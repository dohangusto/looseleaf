import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    headerView

                    // Pinned card stays fixed while the grid scrolls beneath it.
                    if let featured = viewModel.featuredEntry {
                        NavigationLink(value: featured) {
                            FeaturedCardView(entry: featured)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 28)
                    }

                    ScrollView(showsIndicators: false) {
                        StaggeredGridView(entries: viewModel.gridEntries)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100)
                    }
                }

                VStack {
                    Spacer()
                    bottomToolbar
                }
            }
            .navigationDestination(for: JournalEntry.self) { _ in
                CardDetailView()
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("Looseleaf")
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()

            Menu {
                Button {
                    viewModel.selectedFilter = nil
                } label: {
                    if viewModel.selectedFilter == nil {
                        Label("All", systemImage: "checkmark")
                    } else {
                        Text("All")
                    }
                }

                ForEach(JournalLevel.allCases) { level in
                    Button {
                        viewModel.selectedFilter = level
                    } label: {
                        if viewModel.selectedFilter == level {
                            Label(level.rawValue.capitalized, systemImage: "checkmark")
                        } else {
                            Text(level.rawValue.capitalized)
                        }
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.black)
                    .frame(width: 52, height: 52)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.black)
                    .frame(width: 52, height: 52)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }

            Spacer()

            Text("\(viewModel.totalPages)")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: {}) {
                Image(systemName: "square.and.pencil")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.black)
                    .frame(width: 52, height: 52)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
}

#Preview {
    HomeView()
}
