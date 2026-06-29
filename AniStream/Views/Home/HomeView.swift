import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var featuredIndex = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if viewModel.isLoading {
                    LoadingView()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            // MARK: - Featured Hero Carousel
                            featuredCarousel
                            
                            // MARK: - Trending Section
                            VStack(spacing: 16) {
                                SectionHeader(title: "Trending Now 🔥")
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.trendingAnime) { anime in
                                            AnimeCardView(anime: anime)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.top, 24)
                            
                            // MARK: - Recently Added Section
                            VStack(spacing: 16) {
                                SectionHeader(title: "Neu hinzugefügt ✨")
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.recentlyAdded) { anime in
                                            AnimeCardView(anime: anime, width: 150, height: 225)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.top, 24)
                            
                            // MARK: - All Anime Grid
                            VStack(spacing: 16) {
                                SectionHeader(title: "Alle Anime", showSeeAll: false)
                                
                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible(), spacing: 12),
                                        GridItem(.flexible(), spacing: 12),
                                        GridItem(.flexible(), spacing: 12)
                                    ],
                                    spacing: 16
                                ) {
                                    ForEach(viewModel.trendingAnime + viewModel.recentlyAdded) { anime in
                                        AnimeCardView(anime: anime, width: 110, height: 160)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.top, 24)
                            .padding(.bottom, 100)
                        }
                    }
                    .ignoresSafeArea(edges: .top)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Featured Carousel
    
    @ViewBuilder
    private var featuredCarousel: some View {
        if !viewModel.featuredAnime.isEmpty {
            ZStack(alignment: .bottom) {
                TabView(selection: $featuredIndex) {
                    ForEach(Array(viewModel.featuredAnime.enumerated()), id: \.element.id) { index, anime in
                        HeroBannerCard(anime: anime)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 420)
                
                // Page indicator dots
                HStack(spacing: 6) {
                    ForEach(0..<viewModel.featuredAnime.count, id: \.self) { index in
                        Circle()
                            .fill(index == featuredIndex ? Color.white : Color.white.opacity(0.4))
                            .frame(width: index == featuredIndex ? 8 : 5,
                                   height: index == featuredIndex ? 8 : 5)
                            .animation(.spring(response: 0.3), value: featuredIndex)
                    }
                }
                .padding(.bottom, 12)
            }
            .onAppear {
                startAutoScroll()
            }
        }
    }
    
    private func startAutoScroll() {
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                featuredIndex = (featuredIndex + 1) % max(1, viewModel.featuredAnime.count)
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.accentColor)
            Text("Lade Inhalte...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
}
