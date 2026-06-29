import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var results: [Anime] = []
    @Published var selectedGenres: Set<String> = []
    @Published var selectedType: Anime.AnimeType? = nil
    @Published var selectedYear: Int? = nil
    @Published var isSearching = false
    @Published var showFilters = false
    
    private let dataService = MockDataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var availableYears: [Int] {
        Array(Set(dataService.allAnime.map { $0.releaseYear })).sorted(by: >)
    }
    
    var hasActiveFilters: Bool {
        !selectedGenres.isEmpty || selectedType != nil || selectedYear != nil
    }
    
    init() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.performSearch()
            }
            .store(in: &cancellables)
        
        $selectedGenres
            .sink { [weak self] _ in self?.performSearch() }
            .store(in: &cancellables)
        
        $selectedType
            .sink { [weak self] _ in self?.performSearch() }
            .store(in: &cancellables)
        
        $selectedYear
            .sink { [weak self] _ in self?.performSearch() }
            .store(in: &cancellables)
    }
    
    func performSearch() {
        isSearching = true
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            self.results = dataService.search(
                query: searchQuery,
                genres: Array(selectedGenres),
                type: selectedType,
                year: selectedYear
            )
            self.isSearching = false
        }
    }
    
    func clearFilters() {
        selectedGenres = []
        selectedType = nil
        selectedYear = nil
    }
    
    func toggleGenre(_ genre: String) {
        if selectedGenres.contains(genre) {
            selectedGenres.remove(genre)
        } else {
            selectedGenres.insert(genre)
        }
    }
}
