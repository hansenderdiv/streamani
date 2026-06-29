import Foundation
import AVFoundation
import Combine

enum PlayerState: Equatable {
    case idle
    case sniffing
    case loading
    case playing
    case paused
    case error(String)
}

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published var playerState: PlayerState = .idle
    @Published var player: AVPlayer?
    @Published var isShowingWebView = false
    @Published var webViewURL: URL?
    @Published var sniffedStreamURL: URL?
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isBuffering = false
    @Published var playbackRate: Float = 1.0
    @Published var isMuted = false
    @Published var showControls = true
    @Published var currentStreamLink: StreamLink?
    @Published var currentEpisode: Episode?
    @Published var currentAnime: Anime?
    
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Interface
    
    func startStream(link: StreamLink, episode: Episode, anime: Anime) {
        currentStreamLink = link
        currentEpisode = episode
        currentAnime = anime
        playerState = .sniffing
        isShowingWebView = true
        
        if let url = URL(string: link.url) {
            webViewURL = url
        }
    }
    
    // Called by the WebView sniffer when a stream URL is found
    func didSniffStreamURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            playerState = .error("Ungültige Stream-URL")
            isShowingWebView = false
            return
        }
        
        sniffedStreamURL = url
        isShowingWebView = false
        playerState = .loading
        
        setupPlayer(with: url)
    }
    
    func didFailSniffing(error: String) {
        isShowingWebView = false
        playerState = .error(error)
    }
    
    // MARK: - AVPlayer Setup
    
    private func setupPlayer(with url: URL) {
        let playerItem = AVPlayerItem(url: url)
        
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }
        
        setupTimeObserver()
        
        // Observe status
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    self?.playerState = .playing
                    self?.duration = playerItem.duration.seconds
                    self?.player?.play()
                case .failed:
                    self?.playerState = .error(playerItem.error?.localizedDescription ?? "Unbekannter Fehler")
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Observe buffering
        playerItem.publisher(for: \.isPlaybackLikelyToKeepUp)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isReady in
                self?.isBuffering = !isReady
            }
            .store(in: &cancellables)
    }
    
    private func setupTimeObserver() {
        removeTimeObserver()
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
    }
    
    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    // MARK: - Playback Controls
    
    func togglePlayPause() {
        guard let player = player else { return }
        if player.timeControlStatus == .playing {
            player.pause()
            playerState = .paused
        } else {
            player.play()
            playerState = .playing
        }
    }
    
    func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    func skipForward(seconds: Double = 10) {
        seek(to: currentTime + seconds)
    }
    
    func skipBackward(seconds: Double = 10) {
        seek(to: max(0, currentTime - seconds))
    }
    
    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        player?.rate = rate
    }
    
    func toggleMute() {
        isMuted.toggle()
        player?.isMuted = isMuted
    }
    
    func stopPlayback() {
        player?.pause()
        removeTimeObserver()
        player = nil
        playerState = .idle
        sniffedStreamURL = nil
        cancellables.removeAll()
    }
    
    var formattedCurrentTime: String {
        formatTime(currentTime)
    }
    
    var formattedDuration: String {
        formatTime(duration)
    }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
    
    deinit {
        // Cannot call MainActor-isolated methods from deinit
        // Time observer cleanup is handled in stopPlayback()
    }
}
