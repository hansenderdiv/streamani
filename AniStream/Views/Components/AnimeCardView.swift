import SwiftUI

// MARK: - Anime Poster Card

struct AnimeCardView: View {
    let anime: Anime
    var width: CGFloat = 130
    var height: CGFloat = 195
    
    var body: some View {
        NavigationLink(destination: AnimeDetailView(anime: anime)) {
            VStack(alignment: .leading, spacing: 6) {
                // Cover Image
                AsyncImage(url: URL(string: anime.coverImageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                ProgressView()
                                    .tint(.white)
                            )
                    }
                }
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .overlay(alignment: .topTrailing) {
                    // Type badge
                    Text(anime.type.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(6)
                }
                .overlay(alignment: .bottomLeading) {
                    // Rating badge
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", anime.rating))
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.7))
                    .clipShape(Capsule())
                    .padding(6)
                }
                
                // Title
                Text(anime.titleGerman ?? anime.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .frame(width: width, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Featured Hero Banner Card

struct HeroBannerCard: View {
    let anime: Anime
    
    var body: some View {
        NavigationLink(destination: AnimeDetailView(anime: anime)) {
            ZStack(alignment: .bottomLeading) {
                // Banner Image
                AsyncImage(url: URL(string: anime.bannerImageURL ?? anime.coverImageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple.opacity(0.6), .blue.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 420)
                .clipped()
                
                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.7), .black.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Content
                VStack(alignment: .leading, spacing: 10) {
                    // Genres
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(anime.genres.prefix(3), id: \.self) { genre in
                                Text(genre)
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.white.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    // Title
                    Text(anime.titleGerman ?? anime.title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .shadow(radius: 4)
                    
                    // Synopsis
                    Text(anime.synopsis)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        // Play Button
                        Label("Jetzt ansehen", systemImage: "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .clipShape(Capsule())
                        
                        // Info Button
                        Label("Info", systemImage: "info.circle")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .clipShape(RoundedRectangle(cornerRadius: 0))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 16
    
    init(cornerRadius: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var showSeeAll: Bool = true
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
            
            if showSeeAll {
                Button(action: { action?() }) {
                    Text("Alle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Genre Tag

struct GenreTag: View {
    let genre: String
    var isSelected: Bool = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            Text(genre)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.white.opacity(0.1))
                .foregroundColor(isSelected ? .white : .secondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Rating Stars

struct RatingView: View {
    let rating: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 13))
            Text(String(format: "%.1f", rating))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
            Text("/ 10")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Language Badge

struct LanguageBadge: View {
    let language: StreamLanguage
    
    var body: some View {
        Text(language.rawValue)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.2))
            .foregroundColor(badgeColor)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(badgeColor.opacity(0.4), lineWidth: 1)
            )
    }
    
    var badgeColor: Color {
        switch language {
        case .germanDub: return .green
        case .germanSub: return .blue
        case .englishDub: return .orange
        case .englishSub: return .purple
        case .japanese: return .red
        }
    }
}
