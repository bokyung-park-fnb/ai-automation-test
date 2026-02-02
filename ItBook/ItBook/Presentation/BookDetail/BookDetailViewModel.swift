import Foundation
import Combine

final class BookDetailViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var bookDetail: BookDetail?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isFavorite = false

    // MARK: - Properties

    let isbn13: String
    private let searchBooksUseCase: SearchBooksUseCaseProtocol
    private let favoritesUseCase: ManageFavoritesUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        isbn13: String,
        searchBooksUseCase: SearchBooksUseCaseProtocol? = nil,
        favoritesUseCase: ManageFavoritesUseCaseProtocol? = nil
    ) {
        self.isbn13 = isbn13

        let bookRepository = BookRepository()
        let favoriteRepository = FavoriteRepository()

        self.searchBooksUseCase = searchBooksUseCase ?? SearchBooksUseCase(repository: bookRepository)
        self.favoritesUseCase = favoritesUseCase ?? ManageFavoritesUseCase(repository: favoriteRepository)
    }

    // MARK: - Public Methods

    func loadBookDetail() {
        isLoading = true
        errorMessage = nil

        searchBooksUseCase.fetchBookDetail(isbn13: isbn13)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] detail in
                self?.bookDetail = detail
                self?.checkFavoriteStatus()
            }
            .store(in: &cancellables)
    }

    func toggleFavorite() {
        guard let detail = bookDetail else { return }

        let favoriteBook = FavoriteBook(
            isbn13: detail.isbn13,
            title: detail.title,
            subtitle: detail.subtitle,
            authors: detail.authors,
            publisher: detail.publisher,
            imageURL: detail.imageURL,
            price: detail.price,
            year: detail.year,
            rating: detail.rating
        )

        favoritesUseCase.toggleFavorite(favoriteBook)
            .sink { _ in } receiveValue: { [weak self] newStatus in
                self?.isFavorite = newStatus
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Methods

    private func checkFavoriteStatus() {
        favoritesUseCase.isFavorite(isbn13: isbn13)
            .sink { _ in } receiveValue: { [weak self] status in
                self?.isFavorite = status
            }
            .store(in: &cancellables)
    }
}
