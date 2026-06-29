import SwiftUI
import SwiftData

struct WatchlistView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WatchlistItem.addedDate, order: .reverse) private var watchlistItems: [WatchlistItem]
    @Query(sort: \HistoryItem.watchedDate, order: .reverse) private var historyItems: [HistoryItem]
    
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Tab Selector
                    tabSelector
                    
                    // MARK: - Content
                    if selectedTab == 0 {
                        watchlistContent
                    } else {
                        historyContent
                    }
                }
            }
            .navigationTitle("Meine Liste")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.black, for: .navigationBar)
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "Watchlist", icon: "bookmark.fill", index: 0)
            tabButton(title: "Verlauf", icon: "clock.fill", index: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private func tabButton(title: String, icon: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedTab = index
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selectedTab == index ? Color.accentColor : Color.white.opacity(0.08))
            .foregroundColor(selectedTab == index ? .white : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Watchlist Content
    
    @ViewBuilder
    private var watchlistContent: some View {
        if watchlistItems.isEmpty {
            emptyState(
                icon: "bookmark",
                title: "Watchlist ist leer",
                message: "Füge Anime und Filme zu deiner Watchlist hinzu, um sie hier zu sehen."
            )
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(watchlistItems) { item in
                        WatchlistItemRow(item: item) {
                            modelContext.delete(item)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
        }
    }
    
    // MARK: - History Content
    
    @ViewBuilder
    private var historyContent: some View {
        if historyItems.isEmpty {
            emptyState(
                icon: "clock",
                title: "Kein Verlauf",
                message: "Dein Schau-Verlauf wird hier angezeigt, sobald du Episoden ansiehst."
            )
        } else {
            ScrollView(showsIndicators: false) {
                // Group by date
                let grouped = groupHistoryByDate(historyItems)
                
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(grouped.keys.sorted(by: >), id: \.self) { date in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(formatDate(date))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            
                            ForEach(grouped[date] ?? []) { item in
                                HistoryItemRow(item: item) {
                                    modelContext.delete(item)
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
        }
    }
    
    // MARK: - Empty State
    
    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text(title)
                .font(.system(size: 18, weight: .semibold))
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
    
    // MARK: - Helpers
    
    private func groupHistoryByDate(_ items: [HistoryItem]) -> [Date: [HistoryItem]] {
        let calendar = Calendar.current
        var grouped: [Date: [HistoryItem]] = [:]
        for item in items {
            let day = calendar.startOfDay(for: item.watchedDate)
            grouped[day, default: []].append(item)
        }
        return grouped
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Heute" }
        if calendar.isDateInYesterday(date) { return "Gestern" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Watchlist Item Row

struct WatchlistItemRow: View {
    let item: WatchlistItem
    let onDelete: () -> Void
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateStyle = .medium
        return f
    }()
    
    var body: some View {
        let anime = MockDataService.shared.allAnime.first { $0.id == item.animeId }
        
        Group {
            if let anime = anime {
                NavigationLink(destination: AnimeDetailView(anime: anime)) {
                    rowContent
                }
                .buttonStyle(.plain)
            } else {
                rowContent
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Entfernen", systemImage: "trash")
            }
        }
    }
    
    private var rowContent: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: item.coverImageURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.titleGerman ?? item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(2)
                
                Text(item.type)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", item.rating))
                        .font(.system(size: 12))
                }
                
                Text("Hinzugefügt: \(dateFormatter.string(from: item.addedDate))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
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
}

// MARK: - History Item Row

struct HistoryItemRow: View {
    let item: HistoryItem
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: item.coverImageURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: 70, height: 45)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(alignment: .bottomTrailing) {
                // Progress overlay
                if item.progress > 0 {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: geo.size.width * item.progress, height: 3)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.animeTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                
                Text("Episode \(item.episodeNumber): \(item.episodeTitle)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if item.progress > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.accentColor)
                        Text("\(Int(item.progress * 100))% gesehen")
                            .font(.system(size: 11))
                            .foregroundColor(.accentColor)
                    }
                }
            }
            
            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Löschen", systemImage: "trash")
            }
        }
    }
}

#Preview {
    WatchlistView()
        .modelContainer(for: [WatchlistItem.self, HistoryItem.self], inMemory: true)
        .preferredColorScheme(.dark)
}
