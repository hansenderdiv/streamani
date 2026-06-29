import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Search Bar
                    searchBar
                    
                    // MARK: - Filter Row
                    filterRow
                    
                    // MARK: - Active Filters
                    if viewModel.hasActiveFilters {
                        activeFiltersRow
                    }
                    
                    // MARK: - Results
                    resultsView
                }
            }
            .navigationTitle("Suche")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.black, for: .navigationBar)
            .sheet(isPresented: $viewModel.showFilters) {
                FilterSheet(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Anime, Filme suchen...", text: $viewModel.searchQuery)
                    .focused($isSearchFocused)
                    .autocorrectionDisabled()
                    .onSubmit { viewModel.performSearch() }
                
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            if isSearchFocused {
                Button("Abbrechen") {
                    isSearchFocused = false
                    viewModel.searchQuery = ""
                }
                .font(.system(size: 14))
                .foregroundColor(.accentColor)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
    }
    
    // MARK: - Filter Row
    
    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Filter Button
                Button {
                    viewModel.showFilters = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                        Text("Filter")
                        if viewModel.hasActiveFilters {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(viewModel.hasActiveFilters ? Color.accentColor.opacity(0.2) : Color.white.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(
                            viewModel.hasActiveFilters ? Color.accentColor.opacity(0.5) : Color.clear,
                            lineWidth: 1
                        )
                    )
                }
                
                // Quick Genre Filters
                ForEach(AnimeGenre.allCases.prefix(8), id: \.self) { genre in
                    GenreTag(
                        genre: genre.rawValue,
                        isSelected: viewModel.selectedGenres.contains(genre.rawValue)
                    ) {
                        viewModel.toggleGenre(genre.rawValue)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Active Filters
    
    private var activeFiltersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text("Filter:")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                if let type = viewModel.selectedType {
                    filterChip(text: type.rawValue) {
                        viewModel.selectedType = nil
                    }
                }
                
                if let year = viewModel.selectedYear {
                    filterChip(text: String(year)) {
                        viewModel.selectedYear = nil
                    }
                }
                
                ForEach(Array(viewModel.selectedGenres), id: \.self) { genre in
                    filterChip(text: genre) {
                        viewModel.toggleGenre(genre)
                    }
                }
                
                Button("Alle löschen") {
                    viewModel.clearFilters()
                }
                .font(.system(size: 12))
                .foregroundColor(.red)
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
    }
    
    private func filterChip(text: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.system(size: 12))
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.accentColor.opacity(0.2))
        .foregroundColor(.accentColor)
        .clipShape(Capsule())
    }
    
    // MARK: - Results
    
    @ViewBuilder
    private var resultsView: some View {
        if viewModel.isSearching {
            Spacer()
            ProgressView()
                .tint(.accentColor)
            Spacer()
        } else if viewModel.searchQuery.isEmpty && !viewModel.hasActiveFilters {
            // Default: Show all anime
            defaultContent
        } else if viewModel.results.isEmpty {
            emptyState
        } else {
            searchResults
        }
    }
    
    private var defaultContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Alle Titel")
                    .font(.system(size: 18, weight: .bold))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 16
                ) {
                    ForEach(MockDataService.shared.allAnime) { anime in
                        AnimeCardView(anime: anime)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
    }
    
    private var searchResults: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(viewModel.results.count) Ergebnisse")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.results) { anime in
                        SearchResultRow(anime: anime)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("Keine Ergebnisse")
                .font(.system(size: 18, weight: .semibold))
            Text("Versuche andere Suchbegriffe oder Filter.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let anime: Anime
    
    var body: some View {
        NavigationLink(destination: AnimeDetailView(anime: anime)) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: anime.coverImageURL)) { phase in
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
                    Text(anime.titleGerman ?? anime.title)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Text(String(anime.releaseYear))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text(anime.type.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    RatingView(rating: anime.rating)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(anime.genres.prefix(3), id: \.self) { genre in
                                Text(genre)
                                    .font(.system(size: 10))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @ObservedObject var viewModel: SearchViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                List {
                    // Type Filter
                    Section("Typ") {
                        ForEach(Anime.AnimeType.allCases, id: \.self) { type in
                            Button {
                                viewModel.selectedType = viewModel.selectedType == type ? nil : type
                            } label: {
                                HStack {
                                    Text(type.rawValue)
                                    Spacer()
                                    if viewModel.selectedType == type {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                    }
                    
                    // Year Filter
                    Section("Jahr") {
                        ForEach(viewModel.availableYears, id: \.self) { year in
                            Button {
                                viewModel.selectedYear = viewModel.selectedYear == year ? nil : year
                            } label: {
                                HStack {
                                    Text(String(year))
                                    Spacer()
                                    if viewModel.selectedYear == year {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                    }
                    
                    // Genre Filter
                    Section("Genre") {
                        ForEach(AnimeGenre.allCases, id: \.self) { genre in
                            Button {
                                viewModel.toggleGenre(genre.rawValue)
                            } label: {
                                HStack {
                                    Text(genre.rawValue)
                                    Spacer()
                                    if viewModel.selectedGenres.contains(genre.rawValue) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Zurücksetzen") {
                        viewModel.clearFilters()
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    SearchView()
        .preferredColorScheme(.dark)
}
