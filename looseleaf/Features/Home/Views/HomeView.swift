import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var path: [JournalEntry] = []
    @State private var isSearching = false
    @State private var pdfURL: URL?
    @State private var showShareSheet = false
    @FocusState private var searchFocused: Bool
    @Namespace private var heroNamespace
    @AppStorage("cardDarkModeEnabled") private var isDarkModeEnabled = false

    private var searchText: Binding<String> {
        Binding(get: { viewModel.searchQuery }, set: { viewModel.searchQuery = $0 })
    }

    private var sortBinding: Binding<SortOrder> {
        Binding(get: { viewModel.sortOrder }, set: { viewModel.sortOrder = $0 })
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    headerView

                    if viewModel.selectedFilter != nil {
                        filterChip
                    }

                    content
                }

                // Floats above the keyboard, just like the Page bottom tools.
                VStack {
                    Spacer()
                    if isSearching {
                        searchBar
                    } else {
                        bottomToolbar
                    }
                }
            }
            .navigationDestination(for: JournalEntry.self) { entry in
                CardDetailView(entry: entry)
                    .zoomDestination(id: entry.id, in: heroNamespace)
            }
        }
        .environment(viewModel)
        .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
        .sheet(isPresented: $showShareSheet) {
            if let pdfURL { ActivityView(items: [pdfURL]) }
        }
    }

    // MARK: - Card actions

    private func pin(_ entry: JournalEntry) {
        Haptics.tap()
        viewModel.togglePin(entry)
    }

    private func duplicate(_ entry: JournalEntry) {
        Haptics.tap()
        viewModel.duplicate(entry)
    }

    private func delete(_ entry: JournalEntry) {
        Haptics.warning()
        withAnimation { viewModel.delete(entry) }
    }

    private func share(_ entry: JournalEntry) {
        let blocks = entry.pages.flatMap { $0.blocks }
        pdfURL = PagePDFRenderer.makePDF(title: entry.title, blocks: blocks)
        if pdfURL != nil { showShareSheet = true }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.hasResults {
            VStack(spacing: 0) {
                // Pinned card stays fixed while the grid scrolls beneath it.
                if let featured = viewModel.featuredEntry {
                    NavigationLink(value: featured) {
                        FeaturedCardView(entry: featured)
                    }
                    .buttonStyle(.plain)
                    .zoomSource(id: featured.id, in: heroNamespace)
                    .entryContextMenu(
                        isPinned: featured.isPinned,
                        onPin: { pin(featured) },
                        onShare: { share(featured) },
                        onDuplicate: { duplicate(featured) },
                        onDelete: { delete(featured) }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        ForEach(viewModel.gridSections) { section in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(section.title)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 4)

                                StaggeredGridView(
                                    entries: section.entries,
                                    heroNamespace: heroNamespace,
                                    onPin: pin,
                                    onShare: share,
                                    onDuplicate: duplicate,
                                    onDelete: delete
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: viewModel.isSearchActive ? "text.magnifyingglass" : "tray")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(emptyTitle)
                .font(.headline)
            Text(emptyMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
    }

    private var emptyTitle: String {
        viewModel.isSearchActive ? "No matches" : "Nothing here yet"
    }

    private var emptyMessage: String {
        if viewModel.isSearchActive {
            return "No notes match “\(viewModel.searchQuery)”. Try a different keyword."
        }
        return "No notes for this filter. Try a different mood or clear the filter."
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

                Divider()

                Picker("Sort", selection: sortBinding) {
                    ForEach(SortOrder.allCases) { order in
                        Text(order.label).tag(order)
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .frame(width: 52, height: 52)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .tint(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            // Expanded search field island.
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search notes", text: searchText)
                    .focused($searchFocused)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)

            // Cancel searching island.
            Button { exitSearch() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .onAppear { searchFocused = true }
    }

    private var filterChip: some View {
        HStack {
            Button {
                viewModel.selectedFilter = nil
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.selectedFilter?.icon ?? "line.3.horizontal.decrease")
                        .font(.caption)
                    Text(viewModel.selectedFilter?.rawValue.capitalized ?? "")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Image(systemName: "xmark")
                        .font(.caption2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background((viewModel.selectedFilter?.color ?? .gray).opacity(0.15), in: Capsule())
                .foregroundStyle(viewModel.selectedFilter?.color ?? .primary)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isSearching = true }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .frame(width: 52, height: 52)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                let entry = viewModel.createEntry()
                path.append(entry)
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .frame(width: 52, height: 52)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private func exitSearch() {
        searchFocused = false
        viewModel.searchQuery = ""
        withAnimation(.easeInOut(duration: 0.2)) { isSearching = false }
    }
}

#Preview {
    HomeView()
}
