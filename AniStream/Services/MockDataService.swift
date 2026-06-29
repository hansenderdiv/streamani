import Foundation

// MARK: - Mock Data Service
// Provides sample data for UI development and testing.
// In production, replace with real API calls to your backend.

final class MockDataService {
    static let shared = MockDataService()
    private init() {}
    
    // MARK: - Sample Anime Data
    
    var allAnime: [Anime] {
        return [
            makeDragonBallDaima(),
            makeOnePiece(),
            makeAttackOnTitan(),
            makeDemonSlayer(),
            makeJujutsuKaisen(),
            makeNaruto(),
            makeMyHeroAcademia(),
            makeBlueExorcist(),
            makeFullmetalAlchemist(),
            makeSteinsGate(),
            makeVinlandSaga(),
            makeChainsaw(),
            makeSpyFamily(),
            makeBluelock(),
            makeTowerOfGod()
        ]
    }
    
    var featuredAnime: [Anime] {
        allAnime.filter { $0.isFeatured }
    }
    
    var trendingAnime: [Anime] {
        allAnime.filter { $0.isTrending }
    }
    
    var recentlyAdded: [Anime] {
        allAnime.filter { $0.isRecentlyAdded }
    }
    
    // MARK: - Calendar Releases
    
    var weeklyReleases: [CalendarRelease] {
        let calendar = Calendar.current
        let today = Date()
        var releases: [CalendarRelease] = []
        
        let releaseData: [(String, String, Int, Int, Bool, Bool)] = [
            ("one-piece", "One Piece", 1120, 0, false, true),
            ("dragonball-daima", "Dragon Ball Daima", 22, 1, true, true),
            ("jujutsu-kaisen", "Jujutsu Kaisen", 48, 2, true, true),
            ("demon-slayer", "Demon Slayer", 12, 2, true, true),
            ("my-hero-academia", "My Hero Academia", 145, 3, false, true),
            ("spy-family", "Spy x Family", 38, 4, true, true),
            ("blue-lock", "Blue Lock", 52, 5, false, true),
            ("chainsaw-man", "Chainsaw Man", 24, 5, true, true),
            ("vinland-saga", "Vinland Saga", 48, 6, false, true),
            ("tower-of-god", "Tower of God", 26, 6, true, true),
        ]
        
        for (id, title, ep, dayOffset, hasDub, hasSub) in releaseData {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                releases.append(CalendarRelease(
                    id: "\(id)-ep\(ep)",
                    animeTitle: title,
                    episodeNumber: ep,
                    releaseDate: date,
                    coverImageURL: coverURL(for: id),
                    hasGermanDub: hasDub,
                    hasGermanSub: hasSub,
                    animeId: id
                ))
            }
        }
        return releases
    }
    
    // MARK: - Search
    
    func search(query: String, genres: [String], type: Anime.AnimeType?, year: Int?) -> [Anime] {
        var results = allAnime
        
        if !query.isEmpty {
            results = results.filter {
                $0.title.localizedCaseInsensitiveContains(query) ||
                ($0.titleGerman?.localizedCaseInsensitiveContains(query) ?? false) ||
                $0.synopsis.localizedCaseInsensitiveContains(query)
            }
        }
        
        if !genres.isEmpty {
            results = results.filter { anime in
                genres.allSatisfy { genre in anime.genres.contains(genre) }
            }
        }
        
        if let type = type {
            results = results.filter { $0.type == type }
        }
        
        if let year = year {
            results = results.filter { $0.releaseYear == year }
        }
        
        return results
    }
    
    // MARK: - Private Helpers
    
    private func coverURL(for id: String) -> String {
        // Using picsum for placeholder images keyed by anime id hash
        let seed = abs(id.hashValue) % 1000
        return "https://picsum.photos/seed/\(seed)/400/600"
    }
    
    private func bannerURL(for id: String) -> String {
        let seed = (abs(id.hashValue) % 1000) + 500
        return "https://picsum.photos/seed/\(seed)/800/450"
    }
    
    private func makeEpisodes(count: Int, animeId: String, hasDub: Bool) -> [Episode] {
        (1...max(1, count)).map { i in
            Episode(
                id: "\(animeId)-ep\(i)",
                number: i,
                title: "Episode \(i)",
                synopsis: "Folge \(i) der Serie.",
                thumbnailURL: "https://picsum.photos/seed/\(animeId)\(i)/320/180",
                duration: 1440,
                airDate: Calendar.current.date(byAdding: .day, value: -(count - i) * 7, to: Date()),
                streamLinks: makeStreamLinks(animeId: animeId, episode: i, hasDub: hasDub),
                hasGermanDub: hasDub,
                hasGermanSub: true
            )
        }
    }
    
    private func makeStreamLinks(animeId: String, episode: Int, hasDub: Bool) -> [StreamLink] {
        var links: [StreamLink] = [
            StreamLink(
                id: "\(animeId)-ep\(episode)-sub-voe",
                provider: .voe,
                url: "https://voe.sx/e/placeholder",
                language: .germanSub,
                quality: .hd1080
            ),
            StreamLink(
                id: "\(animeId)-ep\(episode)-sub-vidmoly",
                provider: .vidmoly,
                url: "https://vidmoly.to/embed/placeholder",
                language: .germanSub,
                quality: .hd720
            )
        ]
        
        if hasDub {
            links.append(StreamLink(
                id: "\(animeId)-ep\(episode)-dub-voe",
                provider: .voe,
                url: "https://voe.sx/e/placeholder-dub",
                language: .germanDub,
                quality: .hd1080
            ))
        }
        
        return links
    }
    
    // MARK: - Individual Anime Factories
    
    private func makeDragonBallDaima() -> Anime {
        Anime(
            id: "dragonball-daima",
            title: "Dragon Ball Daima",
            titleGerman: "Dragon Ball Daima",
            synopsis: "Durch einen Trick der Götter werden Goku und seine Freunde in kleine Kinder verwandelt. Um den Fluch zu brechen, müssen sie in die Dämonenwelt reisen.",
            coverImageURL: "https://picsum.photos/seed/dbdaima/400/600",
            bannerImageURL: "https://picsum.photos/seed/dbdaimabanner/800/450",
            genres: ["Action", "Abenteuer", "Fantasy"],
            type: .series,
            status: .ongoing,
            releaseYear: 2024,
            rating: 8.4,
            episodeCount: 20,
            episodes: makeEpisodes(count: 20, animeId: "dragonball-daima", hasDub: true),
            streamProviders: [.voe, .vidmoly],
            isTrending: true,
            isRecentlyAdded: false,
            isFeatured: true
        )
    }
    
    private func makeOnePiece() -> Anime {
        Anime(
            id: "one-piece",
            title: "One Piece",
            titleGerman: "One Piece",
            synopsis: "Monkey D. Ruffy träumt davon, der König der Piraten zu werden. Er reist mit seiner Crew durch die Grand Line, um den legendären Schatz One Piece zu finden.",
            coverImageURL: "https://picsum.photos/seed/onepiece/400/600",
            bannerImageURL: "https://picsum.photos/seed/onepiecebanner/800/450",
            genres: ["Action", "Abenteuer", "Komödie"],
            type: .series,
            status: .ongoing,
            releaseYear: 1999,
            rating: 9.0,
            episodeCount: 1119,
            episodes: makeEpisodes(count: 10, animeId: "one-piece", hasDub: true),
            streamProviders: [.voe, .vidmoly, .vidoza],
            isTrending: true,
            isRecentlyAdded: false,
            isFeatured: true
        )
    }
    
    private func makeAttackOnTitan() -> Anime {
        Anime(
            id: "attack-on-titan",
            title: "Attack on Titan",
            titleGerman: "Angriff auf die Titanen",
            synopsis: "In einer Welt, in der gigantische Titanen die Menschheit bedrohen, kämpft Eren Yeager für die Freiheit seiner Welt.",
            coverImageURL: "https://picsum.photos/seed/aot/400/600",
            bannerImageURL: "https://picsum.photos/seed/aotbanner/800/450",
            genres: ["Action", "Drama", "Mystery", "Thriller"],
            type: .series,
            status: .completed,
            releaseYear: 2013,
            rating: 9.1,
            episodeCount: 87,
            episodes: makeEpisodes(count: 10, animeId: "attack-on-titan", hasDub: true),
            streamProviders: [.voe, .vidmoly],
            isTrending: false,
            isRecentlyAdded: false,
            isFeatured: true
        )
    }
    
    private func makeDemonSlayer() -> Anime {
        Anime(
            id: "demon-slayer",
            title: "Demon Slayer",
            titleGerman: "Kimetsu no Yaiba",
            synopsis: "Tanjiro Kamado wird Dämonentöter, um seine in einen Dämon verwandelte Schwester zu retten und Rache an dem Dämon zu nehmen, der seine Familie tötete.",
            coverImageURL: "https://picsum.photos/seed/demonslayer/400/600",
            bannerImageURL: "https://picsum.photos/seed/demonslayerbanner/800/450",
            genres: ["Action", "Fantasy", "Übernatürlich"],
            type: .series,
            status: .ongoing,
            releaseYear: 2019,
            rating: 8.9,
            episodeCount: 44,
            episodes: makeEpisodes(count: 10, animeId: "demon-slayer", hasDub: true),
            streamProviders: [.voe, .vidmoly, .vidoza],
            isTrending: true,
            isRecentlyAdded: false,
            isFeatured: false
        )
    }
    
    private func makeJujutsuKaisen() -> Anime {
        Anime(
            id: "jujutsu-kaisen",
            title: "Jujutsu Kaisen",
            titleGerman: "Jujutsu Kaisen",
            synopsis: "Yuji Itadori verschluckt einen verfluchten Finger und wird zum Gefäß des mächtigsten Fluchs. Er tritt der Jujutsu-Hochschule bei, um alle Finger zu sammeln und Sukuna zu vernichten.",
            coverImageURL: "https://picsum.photos/seed/jjk/400/600",
            bannerImageURL: "https://picsum.photos/seed/jjkbanner/800/450",
            genres: ["Action", "Übernatürlich", "Shounen"],
            type: .series,
            status: .ongoing,
            releaseYear: 2020,
            rating: 8.7,
            episodeCount: 47,
            episodes: makeEpisodes(count: 10, animeId: "jujutsu-kaisen", hasDub: true),
            streamProviders: [.voe, .vidmoly],
            isTrending: true,
            isRecentlyAdded: true,
            isFeatured: false
        )
    }
    
    private func makeNaruto() -> Anime {
        Anime(
            id: "naruto",
            title: "Naruto",
            titleGerman: "Naruto",
            synopsis: "Naruto Uzumaki, ein junger Ninja mit dem Neuntailed Fox in sich, strebt danach, Hokage seines Dorfes zu werden.",
            coverImageURL: "https://picsum.photos/seed/naruto/400/600",
            bannerImageURL: "https://picsum.photos/seed/narutobanner/800/450",
            genres: ["Action", "Abenteuer", "Shounen"],
            type: .series,
            status: .completed,
            releaseYear: 2002,
            rating: 8.4,
            episodeCount: 220,
            episodes: makeEpisodes(count: 10, animeId: "naruto", hasDub: true),
            streamProviders: [.voe, .vidmoly, .vidoza],
            isTrending: false,
            isRecentlyAdded: false,
            isFeatured: false
        )
    }
    
    private func makeMyHeroAcademia() -> Anime {
        Anime(
            id: "my-hero-academia",
            title: "My Hero Academia",
            titleGerman: "Boku no Hero Academia",
            synopsis: "In einer Welt voller Superkräfte träumt der machtlose Izuku Midoriya davon, der größte Held zu werden.",
            coverImageURL: "https://picsum.photos/seed/mha/400/600",
            bannerImageURL: "https://picsum.photos/seed/mhabanner/800/450",
            genres: ["Action", "Shounen", "Schule"],
            type: .series,
            status: .ongoing,
            releaseYear: 2016,
            rating: 8.2,
            episodeCount: 138,
            episodes: makeEpisodes(count: 10, animeId: "my-hero-academia", hasDub: true),
            streamProviders: [.voe, .vidmoly],
            isTrending: false,
            isRecentlyAdded: true,
            isFeatured: false
        )
    }
    
    private func makeBlueExorcist() -> Anime {
        Anime(
            id: "blue-exorcist",
            title: "Blue Exorcist",
            titleGerman: "Ao no Exorcist",
            synopsis: "Rin Okumura entdeckt, dass er der Sohn von Satan ist und beschließt, Exorzist zu werden, um seinen Vater zu bekämpfen.",
            coverImageURL: "https://picsum.photos/seed/blueex/400/600",
            bannerImageURL: "https://picsum.photos/seed/blueexbanner/800/450",
            genres: ["Action", "Fantasy", "Übernatürlich"],
            type: .series,
            status: .completed,
            releaseYear: 2011,
            rating: 7.8,
            episodeCount: 25,
            episodes: makeEpisodes(count: 10, animeId: "blue-exorcist", hasDub: true),
            streamProviders: [.voe, .vidmoly],
            isTrending: false,
            isRecentlyAdded: false,
            isFeatured: false
        )
    }
    
    private func makeFullmetalAlchemist() -> Anime {
        Anime(
            id: "fma-brotherhood",
            title: "Fullmetal Alchemist: Brotherhood",
            titleGerman: "Fullmetal Alchemist: Brotherhood",
            synopsis: "Die Brüder Edward und Alphonse Elric suchen nach dem Stein der Weisen, um ihre Körper nach einem misslungenen Alchemie-Versuch wiederherzustellen.",
            coverImageURL: "https://picsum.photos/seed/fmab/400/600",
            bannerImageURL: "https://picsum.photos/seed/fmabbanner/800/450",
            genres: ["Action", "Abenteuer", "Drama", "Fantasy"],
            type: .series,
            status: .completed,
            releaseYear: 2009,
            rating: 9.1,
            episodeCount: 64,
            episodes: makeEpisodes(count: 10, animeId: "fma-brotherhood", hasDub: true),
            streamProviders: [.voe, .vidmoly, .vidoza],
            isTrending: false,
            isRecentlyAdded: false,
            isFeatured: false
        )
    }
    
    private func makeSteinsGate() -> Anime {
        Anime(
            id: "steins-gate",
            title: "Steins;Gate",
            titleGerman: "Steins;Gate",
            synopsis: "Rintaro Okabe und seine Freunde entdecken versehentlich eine Methode, Nachrichten in die Vergangenheit zu senden, was unvorhergesehene Konsequenzen hat.",
            coverImageURL: "https://picsum.photos/seed/steinsgate/400/600",
            bannerImageURL: "https://picsum.photos/seed/steinsbanner/800/450",
            genres: ["Sci-Fi", "Thriller", "Drama"],
            type: .series,
            status: .completed,
            releaseYear: 2011,
            rating: 9.1,
            episodeCount: 24,
            episodes: makeEpisodes(count: 10, animeId: "steins-gate", hasDub: true),
            streamProviders: [.voe, .vidmoly],
            isTrending: false,
            isRecentlyAdded: false,
            isFeatured: false
        )
    }
    
    private func makeVinlandSaga() -> Anime {
        Anime(
            id: "vinland-saga",
            title: "Vinland Saga",
            titleGerman: "Vinland Saga",
            synopsis: "Thorfinn, Sohn eines legendären Kriegers, sucht nach Rache an dem Mann, der seinen Vater tötete, während er in die Welt der Wikinger eintaucht.",
            coverImageURL: "https://picsum.photos/seed/vinland/400/600",
            bannerImageURL: "https://picsum.photos/seed/vinlandbanner/800/450",
            genres: ["Action", "Abenteuer", "Drama", "Seinen"],
            type: .series,
            status: .completed,
            releaseYear: 2019,
            rating: 8.8,
            episodeCount: 48,
            episodes: makeEpisodes(count: 10, animeId: "vinland-saga", hasDub: false),
            streamProviders: [.voe, .vidmoly],
            isTrending: false,
            isRecentlyAdded: false,
            isFeatured: false
        )
    }
    
    private func makeChainsaw() -> Anime {
        Anime(
            id: "chainsaw-man",
            title: "Chainsaw Man",
            titleGerman: "Chainsaw Man",
            synopsis: "Denji, ein junger Teufelsjäger, verschmilzt mit seinem Kettensägen-Teufel und wird zu Chainsaw Man, einem mächtigen Teufelsjäger.",
            coverImageURL: "https://picsum.photos/seed/chainsaw/400/600",
            bannerImageURL: "https://picsum.photos/seed/chainsawbanner/800/450",
            genres: ["Action", "Horror", "Übernatürlich"],
            type: .series,
            status: .ongoing,
            releaseYear: 2022,
            rating: 8.6,
            episodeCount: 12,
            episodes: makeEpisodes(count: 10, animeId: "chainsaw-man", hasDub: true),
            streamProviders: [.voe, .vidmoly, .vidoza],
            isTrending: true,
            isRecentlyAdded: true,
            isFeatured: false
        )
    }
    
    private func makeSpyFamily() -> Anime {
        Anime(
            id: "spy-family",
            title: "Spy x Family",
            titleGerman: "Spy x Family",
            synopsis: "Ein Spion, eine Auftragskillerin und ein telepathisches Kind geben vor, eine normale Familie zu sein, während sie alle ihre eigenen Geheimnisse verbergen.",
            coverImageURL: "https://picsum.photos/seed/spyfam/400/600",
            bannerImageURL: "https://picsum.photos/seed/spyfambanner/800/450",
            genres: ["Action", "Komödie", "Slice of Life"],
            type: .series,
            status: .ongoing,
            releaseYear: 2022,
            rating: 8.5,
            episodeCount: 37,
            episodes: makeEpisodes(count: 10, animeId: "spy-family", hasDub: true),
            streamProviders: [.voe, .vidmoly],
            isTrending: true,
            isRecentlyAdded: true,
            isFeatured: false
        )
    }
    
    private func makeBluelock() -> Anime {
        Anime(
            id: "blue-lock",
            title: "Blue Lock",
            titleGerman: "Blue Lock",
            synopsis: "300 der besten Jugendfußballer Japans werden in einem experimentellen Programm eingesperrt, um den egoistischsten Stürmer der Welt zu erschaffen.",
            coverImageURL: "https://picsum.photos/seed/bluelock/400/600",
            bannerImageURL: "https://picsum.photos/seed/bluelockbanner/800/450",
            genres: ["Sport", "Action", "Shounen"],
            type: .series,
            status: .ongoing,
            releaseYear: 2022,
            rating: 8.3,
            episodeCount: 24,
            episodes: makeEpisodes(count: 10, animeId: "blue-lock", hasDub: false),
            streamProviders: [.voe, .vidmoly],
            isTrending: true,
            isRecentlyAdded: true,
            isFeatured: false
        )
    }
    
    private func makeTowerOfGod() -> Anime {
        Anime(
            id: "tower-of-god",
            title: "Tower of God",
            titleGerman: "Tower of God",
            synopsis: "Bam betritt den mysteriösen Turm, um seine Freundin Rachel zu finden, und muss dabei gefährliche Prüfungen bestehen.",
            coverImageURL: "https://picsum.photos/seed/towergod/400/600",
            bannerImageURL: "https://picsum.photos/seed/towergodbanner/800/450",
            genres: ["Action", "Abenteuer", "Fantasy", "Mystery"],
            type: .series,
            status: .ongoing,
            releaseYear: 2020,
            rating: 7.9,
            episodeCount: 26,
            episodes: makeEpisodes(count: 10, animeId: "tower-of-god", hasDub: false),
            streamProviders: [.voe, .vidmoly],
            isTrending: false,
            isRecentlyAdded: true,
            isFeatured: false
        )
    }
}
