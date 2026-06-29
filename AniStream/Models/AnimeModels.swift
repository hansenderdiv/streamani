import Foundation
import SwiftData

// MARK: - Anime Model

struct Anime: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let titleGerman: String?
    let synopsis: String
    let coverImageURL: String
    let bannerImageURL: String?
    let genres: [String]
    let type: AnimeType
    let status: AnimeStatus
    let releaseYear: Int
    let rating: Double
    let episodeCount: Int?
    let episodes: [Episode]
    let streamProviders: [StreamProvider]
    let isTrending: Bool
    let isRecentlyAdded: Bool
    let isFeatured: Bool
    
    enum AnimeType: String, Codable, CaseIterable {
        case series = "Serie"
        case movie = "Film"
        case ova = "OVA"
        case special = "Special"
    }
    
    enum AnimeStatus: String, Codable {
        case ongoing = "Laufend"
        case completed = "Abgeschlossen"
        case upcoming = "Demnächst"
    }
}

// MARK: - Episode Model

struct Episode: Identifiable, Codable, Hashable {
    let id: String
    let number: Int
    let title: String
    let synopsis: String?
    let thumbnailURL: String?
    let duration: Int // in seconds
    let airDate: Date?
    let streamLinks: [StreamLink]
    let hasGermanDub: Bool
    let hasGermanSub: Bool
}

// MARK: - Stream Models

struct StreamLink: Identifiable, Codable, Hashable {
    let id: String
    let provider: StreamProvider
    let url: String
    let language: StreamLanguage
    let quality: StreamQuality
}

enum StreamProvider: String, Codable, CaseIterable {
    case voe = "VOE"
    case vidmoly = "Vidmoly"
    case vidoza = "Vidoza"
    case doodstream = "DoodStream"
    case streamtape = "Streamtape"
    case filemoon = "Filemoon"
    case vupload = "Vupload"
    case custom = "Custom"
    
    var iconName: String {
        switch self {
        case .voe: return "play.circle.fill"
        case .vidmoly: return "film.fill"
        case .vidoza: return "tv.fill"
        case .doodstream: return "play.rectangle.fill"
        case .streamtape: return "video.fill"
        case .filemoon: return "moon.fill"
        case .vupload: return "icloud.and.arrow.up.fill"
        case .custom: return "link.circle.fill"
        }
    }
}

enum StreamLanguage: String, Codable, CaseIterable {
    case germanDub = "Ger Dub"
    case germanSub = "Ger Sub"
    case englishSub = "Eng Sub"
    case englishDub = "Eng Dub"
    case japanese = "Japanisch"
}

enum StreamQuality: String, Codable, CaseIterable {
    case hd1080 = "1080p"
    case hd720 = "720p"
    case sd480 = "480p"
    case sd360 = "360p"
    case auto = "Auto"
}

// MARK: - SwiftData Persistent Models

@Model
final class WatchlistItem {
    var animeId: String
    var title: String
    var titleGerman: String?
    var coverImageURL: String
    var type: String
    var addedDate: Date
    var genres: [String]
    var rating: Double
    
    init(animeId: String, title: String, titleGerman: String? = nil,
         coverImageURL: String, type: String, genres: [String], rating: Double) {
        self.animeId = animeId
        self.title = title
        self.titleGerman = titleGerman
        self.coverImageURL = coverImageURL
        self.type = type
        self.addedDate = Date()
        self.genres = genres
        self.rating = rating
    }
}

@Model
final class HistoryItem {
    var animeId: String
    var episodeId: String
    var animeTitle: String
    var episodeNumber: Int
    var episodeTitle: String
    var coverImageURL: String
    var watchedDate: Date
    var progress: Double // 0.0 - 1.0
    var totalDuration: Int
    
    init(animeId: String, episodeId: String, animeTitle: String,
         episodeNumber: Int, episodeTitle: String, coverImageURL: String,
         progress: Double = 0.0, totalDuration: Int = 0) {
        self.animeId = animeId
        self.episodeId = episodeId
        self.animeTitle = animeTitle
        self.episodeNumber = episodeNumber
        self.episodeTitle = episodeTitle
        self.coverImageURL = coverImageURL
        self.watchedDate = Date()
        self.progress = progress
        self.totalDuration = totalDuration
    }
}

// MARK: - Calendar Release Model

struct CalendarRelease: Identifiable {
    let id: String
    let animeTitle: String
    let episodeNumber: Int
    let releaseDate: Date
    let coverImageURL: String
    let hasGermanDub: Bool
    let hasGermanSub: Bool
    let animeId: String
}

// MARK: - Genre

enum AnimeGenre: String, CaseIterable {
    case action = "Action"
    case adventure = "Abenteuer"
    case comedy = "Komödie"
    case drama = "Drama"
    case fantasy = "Fantasy"
    case horror = "Horror"
    case mystery = "Mystery"
    case romance = "Romanze"
    case sciFi = "Sci-Fi"
    case sliceOfLife = "Slice of Life"
    case sports = "Sport"
    case supernatural = "Übernatürlich"
    case thriller = "Thriller"
    case mecha = "Mecha"
    case isekai = "Isekai"
    case shounen = "Shounen"
    case seinen = "Seinen"
    case shoujo = "Shoujo"
}
