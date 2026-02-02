import Foundation
import Combine

final class SearchListViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var books: [Book] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var errorMessage: String?
    @Published var searchQuery = ""

    // MARK: - Properties

    private let searchBooksUseCase: SearchBooksUseCaseProtocol
    private let favoritesUseCase: ManageFavoritesUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    private var currentPage = 1
    private var totalResults = 0
    private var hasMorePages: Bool {
        books.count < totalResults
    }

    // MARK: - Init

    init(
        searchBooksUseCase: SearchBooksUseCaseProtocol? = nil,
        favoritesUseCase: ManageFavoritesUseCaseProtocol? = nil
    ) {
        let bookRepository = BookRepository()
        let favoriteRepository = FavoriteRepository()

        self.searchBooksUseCase = searchBooksUseCase ?? SearchBooksUseCase(repository: bookRepository)
        self.favoritesUseCase = favoritesUseCase ?? ManageFavoritesUseCase(repository: favoriteRepository)

        setupSearchDebounce()
    }

    // MARK: - Public Methods

    func loadNewBooks() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        searchBooksUseCase.fetchNewBooks()
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] books in
                self?.books = books
                self?.totalResults = books.count
                self?.currentPage = 1
            }
            .store(in: &cancellables)
    }

    func searchBooks() {
        guard !searchQuery.isEmpty, !isLoading else { return }

        isLoading = true
        errorMessage = nil
        currentPage = 1

        searchBooksUseCase.searchBooks(query: searchQuery, page: currentPage)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] result in
                self?.books = result.books
                self?.totalResults = result.total
            }
            .store(in: &cancellables)
    }

    func loadMoreIfNeeded(currentItem: Book) {
        guard let index = books.firstIndex(where: { $0.id == currentItem.id }),
              index >= books.count - 3,
              hasMorePages,
              !isLoadingMore,
              !searchQuery.isEmpty else {
            return
        }

        isLoadingMore = true
        currentPage += 1

        searchBooksUseCase.searchBooks(query: searchQuery, page: currentPage)
            .sink { [weak self] completion in
                self?.isLoadingMore = false
                if case .failure = completion {
                    self?.currentPage -= 1
                }
            } receiveValue: { [weak self] result in
                self?.books.append(contentsOf: result.books)
            }
            .store(in: &cancellables)
    }

    func isFavorite(isbn13: String) -> AnyPublisher<Bool, Never> {
        favoritesUseCase.isFavorite(isbn13: isbn13)
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }

    func toggleFavorite(book: Book, detail: BookDetail?) {
        let favoriteBook = FavoriteBook(
            isbn13: book.id,
            title: book.title,
            subtitle: book.subtitle,
            authors: detail?.authors ?? "",
            publisher: detail?.publisher ?? "",
            imageURL: book.imageURL,
            price: book.price,
            year: detail?.year,
            rating: detail?.rating
        )

        favoritesUseCase.toggleFavorite(favoriteBook)
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    // MARK: - Private Methods

    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                if query.isEmpty {
                    self?.loadNewBooks()
                } else {
                    self?.searchBooks()
                }
            }
            .store(in: &cancellables)
    }
}
