import Foundation
import Combine

final class FavoriteListViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var favorites: [FavoriteBook] = []
    @Published private(set) var filteredFavorites: [FavoriteBook] = []
    @Published private(set) var isLoading = false
    @Published var searchQuery = ""
    @Published var sortAscending = true
    @Published var maxPriceFilter: Double?

    // MARK: - Properties

    private let favoritesUseCase: ManageFavoritesUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(favoritesUseCase: ManageFavoritesUseCaseProtocol? = nil) {
        let favoriteRepository = FavoriteRepository()
        self.favoritesUseCase = favoritesUseCase ?? ManageFavoritesUseCase(repository: favoriteRepository)

        setupBindings()
    }

    // MARK: - Public Methods

    func loadFavorites() {
        isLoading = true

        favoritesUseCase.fetchAllFavorites()
            .sink { [weak self] completion in
                self?.isLoading = false
            } receiveValue: { [weak self] books in
                self?.favorites = books
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
    }

    func removeFavorite(_ book: FavoriteBook) {
        favoritesUseCase.removeFavorite(isbn13: book.id)
            .sink { _ in } receiveValue: { [weak self] in
                self?.loadFavorites()
            }
            .store(in: &cancellables)
    }

    func toggleSort() {
        sortAscending.toggle()
    }

    func setPriceFilter(_ maxPrice: Double?) {
        maxPriceFilter = maxPrice
    }

    func clearFilters() {
        searchQuery = ""
        maxPriceFilter = nil
        sortAscending = true
    }

    // MARK: - Private Methods

    private func setupBindings() {
        Publishers.CombineLatest3($searchQuery, $sortAscending, $maxPriceFilter)
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] _, _, _ in
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
    }

    private func applyFiltersAndSort() {
        var result = favorites

        // 검색 필터
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.authors.lowercased().contains(query)
            }
        }

        // 가격 필터
        if let maxPrice = maxPriceFilter {
            result = favoritesUseCase.filterFavorites(result, maxPrice: maxPrice)
        }

        // 정렬
        result = favoritesUseCase.sortFavorites(result, ascending: sortAscending)

        filteredFavorites = result
    }
}
