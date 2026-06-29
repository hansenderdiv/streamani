import SwiftUI
import AVKit
import AVFoundation

// MARK: - Video Player View

struct VideoPlayerView: View {
    let streamLink: StreamLink
    let episode: Episode
    let anime: Anime
    
    @StateObject private var viewModel = PlayerViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @State private var isDraggingSlider = false
    @State private var sliderValue: Double = 0
    @State private var showRateMenu = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            switch viewModel.playerState {
            case .idle:
                Color.black
                
            case .sniffing:
                sniffingView
                
            case .loading:
                loadingView
                
            case .playing, .paused:
                playerContent
                
            case .error(let message):
                errorView(message: message)
            }
        }
        .statusBarHidden(true)
        .onAppear {
            viewModel.startStream(link: streamLink, episode: episode, anime: anime)
        }
        .onDisappear {
            viewModel.stopPlayback()
            saveProgress()
        }
        .sheet(isPresented: $viewModel.isShowingWebView) {
            WebViewSnifferSheet(viewModel: viewModel)
        }
    }
    
    // MARK: - Sniffing View
    
    private var sniffingView: some View {
        VStack(spacing: 24) {
            // Animated radar icon
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.accentColor.opacity(0.3 - Double(i) * 0.08), lineWidth: 2)
                        .frame(width: CGFloat(60 + i * 30), height: CGFloat(60 + i * 30))
                        .scaleEffect(1.0)
                        .animation(
                            .easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.4),
                            value: viewModel.isShowingWebView
                        )
                }
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 30))
                    .foregroundColor(.accentColor)
            }
            .frame(width: 120, height: 120)
            
            VStack(spacing: 8) {
                Text("Stream wird gesucht...")
                    .font(.system(size: 18, weight: .semibold))
                Text("Analysiere \(streamLink.provider.rawValue)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            ProgressView()
                .tint(.accentColor)
            
            Button("Abbrechen") {
                viewModel.stopPlayback()
                dismiss()
            }
            .font(.system(size: 14))
            .foregroundColor(.secondary)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.accentColor)
            Text("Lade Stream...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Player Content
    
    private var playerContent: some View {
        ZStack {
            // Video Layer
            if let player = viewModel.player {
                VideoPlayerLayer(player: player)
                    .ignoresSafeArea()
                    .onTapGesture {
                        toggleControls()
                    }
            }
            
            // Buffering indicator
            if viewModel.isBuffering {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
            
            // Controls Overlay
            if showControls {
                controlsOverlay
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showControls)
        .onAppear { resetControlsTimer() }
    }
    
    // MARK: - Controls Overlay
    
    private var controlsOverlay: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.black.opacity(0.7), .clear, .clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                topBar
                    .padding(.top, 50)
                    .padding(.horizontal, 20)
                
                Spacer()
                
                // Center Controls
                centerControls
                
                Spacer()
                
                // Bottom Bar
                bottomBar
                    .padding(.bottom, 40)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.3))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 2) {
                Text(anime.titleGerman ?? anime.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("Episode \(episode.number) • \(streamLink.language.rawValue)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Playback Rate
            Menu {
                ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { rate in
                    Button("\(rate == 1.0 ? "Normal" : "\(rate)x")") {
                        viewModel.setPlaybackRate(Float(rate))
                    }
                }
            } label: {
                Text("\(viewModel.playbackRate == 1.0 ? "1x" : "\(viewModel.playbackRate)x")")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.3))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Center Controls
    
    private var centerControls: some View {
        HStack(spacing: 50) {
            // Skip Backward 10s
            Button {
                viewModel.skipBackward()
                resetControlsTimer()
            } label: {
                ZStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 30, weight: .medium))
                    Text("10")
                        .font(.system(size: 11, weight: .bold))
                        .offset(y: 2)
                }
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
            }
            
            // Play/Pause
            Button {
                viewModel.togglePlayPause()
                resetControlsTimer()
            } label: {
                Image(systemName: viewModel.playerState == .playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .frame(width: 72, height: 72)
                    .background(.white.opacity(0.15))
                    .clipShape(Circle())
            }
            
            // Skip Forward 10s
            Button {
                viewModel.skipForward()
                resetControlsTimer()
            } label: {
                ZStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 30, weight: .medium))
                    Text("10")
                        .font(.system(size: 11, weight: .bold))
                        .offset(y: 2)
                }
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
            }
        }
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBar: some View {
        VStack(spacing: 12) {
            // Progress Slider
            VStack(spacing: 4) {
                Slider(
                    value: isDraggingSlider ? $sliderValue : .init(
                        get: { viewModel.progress },
                        set: { _ in }
                    ),
                    in: 0...1
                ) { editing in
                    isDraggingSlider = editing
                    if !editing {
                        viewModel.seek(to: sliderValue * viewModel.duration)
                    }
                    resetControlsTimer()
                }
                .accentColor(.white)
                .onChange(of: viewModel.progress) { _, newValue in
                    if !isDraggingSlider {
                        sliderValue = newValue
                    }
                }
                
                HStack {
                    Text(viewModel.formattedCurrentTime)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text(viewModel.formattedDuration)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Bottom Buttons
            HStack {
                // Mute
                Button {
                    viewModel.toggleMute()
                } label: {
                    Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                // Provider info
                HStack(spacing: 4) {
                    Image(systemName: streamLink.provider.iconName)
                        .font(.system(size: 12))
                    Text(streamLink.provider.rawValue)
                        .font(.system(size: 12))
                }
                .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                // AirPlay
                AirPlayButton()
                    .frame(width: 44, height: 44)
            }
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Stream-Fehler")
                .font(.system(size: 20, weight: .bold))
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Schließen") {
                dismiss()
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helpers
    
    private func toggleControls() {
        withAnimation {
            showControls.toggle()
        }
        if showControls {
            resetControlsTimer()
        }
    }
    
    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            withAnimation {
                showControls = false
            }
        }
    }
    
    private func saveProgress() {
        guard viewModel.duration > 0 else { return }
        let progress = viewModel.progress
        guard progress > 0.01 else { return }
        
        // Check if history item exists
        let item = HistoryItem(
            animeId: anime.id,
            episodeId: episode.id,
            animeTitle: anime.titleGerman ?? anime.title,
            episodeNumber: episode.number,
            episodeTitle: episode.title,
            coverImageURL: anime.coverImageURL,
            progress: progress,
            totalDuration: Int(viewModel.duration)
        )
        modelContext.insert(item)
    }
}

// MARK: - Video Player Layer (UIViewRepresentable)

struct VideoPlayerLayer: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> UIView {
        let view = PlayerUIView(player: player)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let playerView = uiView as? PlayerUIView {
            playerView.playerLayer.player = player
        }
    }
}

final class PlayerUIView: UIView {
    let playerLayer = AVPlayerLayer()
    
    init(player: AVPlayer) {
        super.init(frame: .zero)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
        playerLayer.backgroundColor = UIColor.black.cgColor
        layer.addSublayer(playerLayer)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

// MARK: - AirPlay Button

struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.tintColor = .white
        view.activeTintColor = .systemBlue
        return view
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

// MARK: - WebView Sniffer Sheet

struct WebViewSnifferSheet: View {
    @ObservedObject var viewModel: PlayerViewModel
    @State private var sniffer: StreamSniffer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Show the WebView (hidden/minimized for sniffing)
                if let sniffer = sniffer {
                    WebViewRepresentable(webView: sniffer.webView)
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                }
                
                VStack(spacing: 16) {
                    // Animated sniffer indicator
                    ZStack {
                        Circle()
                            .stroke(Color.accentColor.opacity(0.2), lineWidth: 3)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 32))
                            .foregroundColor(.accentColor)
                    }
                    
                    Text("Suche Stream-URL...")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Der Stream-Anbieter wird analysiert.\nBitte warten...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    ProgressView()
                        .tint(.accentColor)
                        .padding(.top, 8)
                    
                    Button("Abbrechen") {
                        sniffer?.stop()
                        viewModel.isShowingWebView = false
                        viewModel.playerState = .error("Abgebrochen")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .onAppear {
            setupSniffer()
        }
        .onDisappear {
            sniffer?.stop()
        }
    }
    
    private func setupSniffer() {
        let s = StreamSniffer()
        s.delegate = SnifferDelegateAdapter(viewModel: viewModel)
        sniffer = s
        
        if let url = viewModel.webViewURL {
            s.sniff(url: url)
        }
    }
}

// MARK: - Sniffer Delegate Adapter

final class SnifferDelegateAdapter: NSObject, StreamSnifferDelegate {
    let viewModel: PlayerViewModel
    
    init(viewModel: PlayerViewModel) {
        self.viewModel = viewModel
    }
    
    func streamSniffer(_ sniffer: StreamSniffer, didFindStreamURL url: URL) {
        Task { @MainActor in
            viewModel.didSniffStreamURL(url.absoluteString)
        }
    }
    
    func streamSniffer(_ sniffer: StreamSniffer, didFailWithError error: String) {
        Task { @MainActor in
            viewModel.didFailSniffing(error: error)
        }
    }
}

// MARK: - WebView Representable

import WebKit

struct WebViewRepresentable: UIViewRepresentable {
    let webView: WKWebView
    
    func makeUIView(context: Context) -> WKWebView {
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
