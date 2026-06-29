import Foundation

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var weeklyReleases: [CalendarRelease] = []
    @Published var selectedDate: Date = Date()
    @Published var isLoading = false
    
    private let dataService = MockDataService.shared
    
    var weekDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }
    
    var releasesForSelectedDate: [CalendarRelease] {
        let calendar = Calendar.current
        return weeklyReleases.filter {
            calendar.isDate($0.releaseDate, inSameDayAs: selectedDate)
        }
    }
    
    func releasesFor(date: Date) -> [CalendarRelease] {
        let calendar = Calendar.current
        return weeklyReleases.filter {
            calendar.isDate($0.releaseDate, inSameDayAs: date)
        }
    }
    
    init() {
        loadReleases()
    }
    
    func loadReleases() {
        isLoading = true
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            self.weeklyReleases = dataService.weeklyReleases
            self.isLoading = false
        }
    }
}
