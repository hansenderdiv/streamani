import SwiftUI
import SwiftData

struct AnimeDetailView: View {
    let anime: Anime
    
    @Environment(\.modelContext) private var modelContext
    @Query private var watchlistItems: [WatchlistItem]
    @State private var selectedEpisode: Episode?
    @State private var showPlayer = false
    @State private var selectedStreamLink: StreamLink?
    @State private var selectedLanguageFilter: StreamLanguage? = nil
    @State private var showEpisodes = true
    
    private var isInWatchlist: Bool {
        watchlistItems.contains { $0.animeId == anime.id }
    }
    
    var filteredEpisodes: [Episode] {
        if let lang = selectedLanguageFilter {
            return anime.episodes.filter { ep in
                ep.streamLinks.contains { $0.language == lang }
            }
        }
        return anime.episodes
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // MARK: - Hero Header
                    heroHeader
                    
                    // MARK: - Info Section
                    infoSection
                    
                    // MARK: - Episode List
                    episodeSection
                        .padding(.bottom, 100)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.black, for: .navigationBar)
        .fullScreenCover(isPresented: $showPlayer) {
            if let episode = selectedEpisode, let link = selectedStreamLink {
                VideoPlayerView(
                    streamLink: link,
                    episode: episode,
                    anime: anime
                )
            }
        }
    }
    
    // MARK: - Hero Header
    
    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: anime.bannerImageURL ?? anime.coverImageURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
            }
            .frame(height: 300)
            .clipped()
            
            LinearGradient(
                colors: [.clear, .black.opacity(0.5), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            
            HStack(alignment: .bottom) {
                // Cover
                AsyncImage(url: URL(string: anime.coverImageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Rectangle().fill(Color.gray.opacity(0.3))
                    }
                }
                .frame(width: 90, height: 135)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(radius: 8)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(anime.titleGerman ?? anime.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Text(String(anime.releaseYear))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(anime.type.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(anime.status.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(anime.status == .ongoing ? .green : .secondary)
                    }
                    
                    RatingView(rating: anime.rating)
                }
                .padding(.leading, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Action Buttons
            HStack(spacing: 12) {
                // Play First Episode
                Button {
                    if let firstEp = anime.episodes.first,
                       let firstLink = firstEp.streamLinks.first {
                        selectedEpisode = firstEp
                        selectedStreamLink = firstLink
                        showPlayer = true
                    }
                } label: {
                    Label("Abspielen", systemImage: "play.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Watchlist Button
                Button {
                    toggleWatchlist()
                } label: {
                    Image(systemName: isInWatchlist ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18))
                        .frame(width: 48, height: 48)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundColor(isInWatchlist ? .accentColor : .white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Genres
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(anime.genres, id: \.self) { genre in
                        GenreTag(genre: genre)
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Synopsis
            VStack(alignment: .leading, spacing: 8) {
                Text("Handlung")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 16)
                
                Text(anime.synopsis)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
            }
            
            // Stats
            HStack(spacing: 0) {
                statItem(value: "\(anime.episodeCount ?? anime.episodes.count)", label: "Episoden")
                Divider().frame(height: 30).background(Color.white.opacity(0.2))
                statItem(value: String(anime.releaseYear), label: "Jahr")
                Divider().frame(height: 30).background(Color.white.opacity(0.2))
                statItem(value: String(format: "%.1f", anime.rating), label: "Bewertung")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Episode Section
    
    private var episodeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with language filter
            HStack {
                Text("Episoden")
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                // Language filter
                Menu {
                    Button("Alle") { selectedLanguageFilter = nil }
                    Divider()
                    ForEach(StreamLanguage.allCases, id: \.self) { lang in
                        Button(lang.rawValue) { selectedLanguageFilter = lang }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedLanguageFilter?.rawValue ?? "Alle")
                            .font(.system(size: 13))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            
            // Episode List
            LazyVStack(spacing: 8) {
                ForEach(filteredEpisodes) { episode in
                    EpisodeRowView(
                        episode: episode,
                        anime: anime
                    ) { link in
                        selectedEpisode = episode
                        selectedStreamLink = link
                        showPlayer = true
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 24)
    }
    
    // MARK: - Helpers
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func toggleWatchlist() {
        if isInWatchlist {
            if let item = watchlistItems.first(where: { $0.animeId == anime.id }) {
                modelContext.delete(item)
            }
        } else {
            let item = WatchlistItem(
                animeId: anime.id,
                title: anime.title,
                titleGerman: anime.titleGerman,
                coverImageURL: anime.coverImageURL,
                type: anime.type.rawValue,
                genres: anime.genres,
                rating: anime.rating
            )
            modelContext.insert(item)
        }
    }
}

// MARK: - Episode Row

struct EpisodeRowView: View {
    let episode: Episode
    let anime: Anime
    let onStreamSelected: (StreamLink) -> Void
    
    @State private var showStreamPicker = false
    
    var body: some View {
        Button {
            if episode.streamLinks.count == 1 {
                onStreamSelected(episode.streamLinks[0])
            } else {
                showStreamPicker = true
            }
        } label: {
            HStack(spacing: 12) {
                // Thumbnail
                AsyncImage(url: URL(string: episode.thumbnailURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "play.fill")
                                    .foregroundColor(.white.opacity(0.5))
                            )
                    }
                }
                .frame(width: 100, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Episode \(episode.number)")
                        .font(.system(size: 13, weight: .semibold))
                    
                    Text(episode.title)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        if episode.hasGermanDub {
                            LanguageBadge(language: .germanDub)
                        }
                        if episode.hasGermanSub {
                            LanguageBadge(language: .germanSub)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showStreamPicker) {
            StreamPickerSheet(episode: episode, onSelect: onStreamSelected)
        }
    }
}

// MARK: - Stream Picker Sheet

struct StreamPickerSheet: View {
    let episode: Episode
    let onSelect: (StreamLink) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                List {
                    ForEach(StreamLanguage.allCases, id: \.self) { lang in
                        let links = episode.streamLinks.filter { $0.language == lang }
                        if !links.isEmpty {
                            Section(lang.rawValue) {
                                ForEach(links) { link in
                                    Button {
                                        dismiss()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            onSelect(link)
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: link.provider.iconName)
                                                .foregroundColor(.accentColor)
                                                .frame(width: 28)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(link.provider.rawValue)
                                                    .font(.system(size: 15, weight: .medium))
                                                Text(link.quality.rawValue)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "play.circle.fill")
                                                .foregroundColor(.accentColor)
                                                .font(.system(size: 22))
                                        }
                                    }
                                    .listRowBackground(Color.white.opacity(0.05))
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Stream auswählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
