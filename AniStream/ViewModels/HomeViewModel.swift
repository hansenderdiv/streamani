import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var featuredAnime: [Anime] = []
    @Published var trendingAnime: [Anime] = []
    @Published var recentlyAdded: [Anime] = []
    @Published var isLoading = false
    @Published var currentFeaturedIndex = 0
    
    private let dataService = MockDataService.shared
    
    init() {
        loadData()
    }
    
    func loadData() {
        isLoading = true
        // Simulate async loading
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            self.featuredAnime = dataService.featuredAnime
            self.trendingAnime = dataService.trendingAnime
            self.recentlyAdded = dataService.recentlyAdded
            self.isLoading = false
        }
    }
}
