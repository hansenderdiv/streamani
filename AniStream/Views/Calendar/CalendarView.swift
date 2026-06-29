import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    
    private let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "EEE"
        return f
    }()
    
    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()
    
    private let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "MMMM yyyy"
        return f
    }()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Month Header
                    monthHeader
                    
                    // MARK: - Week Day Selector
                    weekDaySelector
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // MARK: - Release List
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView().tint(.accentColor)
                        Spacer()
                    } else {
                        releaseList
                    }
                }
            }
            .navigationTitle("Release-Kalender")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.black, for: .navigationBar)
        }
    }
    
    // MARK: - Month Header
    
    private var monthHeader: some View {
        HStack {
            Text(monthFormatter.string(from: viewModel.selectedDate))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                Text("GerDub/Sub Fokus")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Week Day Selector
    
    private var weekDaySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.weekDays, id: \.self) { date in
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate)
                    let isToday = Calendar.current.isDateInToday(date)
                    let releaseCount = viewModel.releasesFor(date: date).count
                    
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.selectedDate = date
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(weekdayFormatter.string(from: date).uppercased())
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(isSelected ? .white : .secondary)
                            
                            ZStack {
                                Circle()
                                    .fill(isSelected ? Color.accentColor : (isToday ? Color.white.opacity(0.15) : Color.clear))
                                    .frame(width: 36, height: 36)
                                
                                Text(dayFormatter.string(from: date))
                                    .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                                    .foregroundColor(isSelected ? .white : .primary)
                            }
                            
                            // Release count indicator
                            if releaseCount > 0 {
                                HStack(spacing: 2) {
                                    ForEach(0..<min(releaseCount, 3), id: \.self) { _ in
                                        Circle()
                                            .fill(isSelected ? Color.white : Color.accentColor)
                                            .frame(width: 4, height: 4)
                                    }
                                }
                            } else {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .frame(width: 48)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Release List
    
    private var releaseList: some View {
        ScrollView(showsIndicators: false) {
            if viewModel.releasesForSelectedDate.isEmpty {
                emptyDayView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.releasesForSelectedDate) { release in
                        CalendarReleaseCard(release: release)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
    }
    
    private var emptyDayView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("Keine Releases")
                .font(.system(size: 18, weight: .semibold))
            Text("An diesem Tag erscheinen keine neuen Episoden.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Calendar Release Card

struct CalendarReleaseCard: View {
    let release: CalendarRelease
    
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.timeStyle = .short
        return f
    }()
    
    var body: some View {
        HStack(spacing: 14) {
            // Cover
            AsyncImage(url: URL(string: release.coverImageURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: 70, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(release.animeTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)
                
                Text("Episode \(release.episodeNumber)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                // Language Badges
                HStack(spacing: 6) {
                    if release.hasGermanDub {
                        LanguageBadge(language: .germanDub)
                    }
                    if release.hasGermanSub {
                        LanguageBadge(language: .germanSub)
                    }
                }
                
                // Release Time
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(timeFormatter.string(from: release.releaseDate))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Notify Button
            Button {
                // TODO: Local notification scheduling
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 18))
                    .foregroundColor(.accentColor)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    CalendarView()
        .preferredColorScheme(.dark)
}
