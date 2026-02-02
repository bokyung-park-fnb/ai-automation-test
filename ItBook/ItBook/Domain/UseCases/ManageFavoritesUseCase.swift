import Foundation
import Combine

// MARK: - Errors

enum FavoritesError: LocalizedError {
    case invalidISBN13(String)
    case invalidPrice(Double)

    var errorDescription: String? {
        switch self {
        case .invalidISBN13(let isbn):
            return "잘못된 ISBN13입니다: \(isbn)"
        case .invalidPrice(let price):
            return "잘못된 가격 필터입니다: \(price)"
        }
    }
}

// MARK: - Protocol

protocol ManageFavoritesUseCaseProtocol: Sendable {
    func fetchAllFavorites() -> AnyPublisher<[FavoriteBook], Error>
    func addFavorite(_ book: FavoriteBook) -> AnyPublisher<Void, Error>
    func removeFavorite(isbn13: String) -> AnyPublisher<Void, Error>
    func isFavorite(isbn13: String) -> AnyPublisher<Bool, Error>
    func toggleFavorite(_ book: FavoriteBook) -> AnyPublisher<Bool, Error>

    /// 로컬 검색 (제목, 저자 기준)
    func searchFavorites(query: String) -> AnyPublisher<[FavoriteBook], Error>

    /// 정렬 (제목 기준)
    func sortFavorites(_ books: [FavoriteBook], ascending: Bool) -> [FavoriteBook]

    /// 필터링 (가격 기준)
    func filterFavorites(_ books: [FavoriteBook], maxPrice: Double) -> [FavoriteBook]
}

// MARK: - Implementation

final class ManageFavoritesUseCase: ManageFavoritesUseCaseProtocol, @unchecked Sendable {

    private let repository: FavoriteRepositoryProtocol

    init(repository: FavoriteRepositoryProtocol) {
        self.repository = repository
    }

    func fetchAllFavorites() -> AnyPublisher<[FavoriteBook], Error> {
        repository.fetchAllFavorites()
    }

    func addFavorite(_ book: FavoriteBook) -> AnyPublisher<Void, Error> {
        repository.addFavorite(book)
    }

    func removeFavorite(isbn13: String) -> AnyPublisher<Void, Error> {
        guard isValidISBN13(isbn13) else {
            return Fail(error: FavoritesError.invalidISBN13(isbn13)).eraseToAnyPublisher()
        }
        return repository.removeFavorite(isbn13: isbn13)
    }

    func isFavorite(isbn13: String) -> AnyPublisher<Bool, Error> {
        guard isValidISBN13(isbn13) else {
            return Fail(error: FavoritesError.invalidISBN13(isbn13)).eraseToAnyPublisher()
        }
        return repository.isFavorite(isbn13: isbn13)
    }

    func toggleFavorite(_ book: FavoriteBook) -> AnyPublisher<Bool, Error> {
        repository.toggleFavorite(book)
    }

    func searchFavorites(query: String) -> AnyPublisher<[FavoriteBook], Error> {
        repository.fetchAllFavorites()
            .map { books in
                guard !query.isEmpty else { return books }
                let lowercasedQuery = query.lowercased()
                return books.filter {
                    $0.title.lowercased().contains(lowercasedQuery) ||
                    $0.authors.lowercased().contains(lowercasedQuery)
                }
            }
            .eraseToAnyPublisher()
    }

    func sortFavorites(_ books: [FavoriteBook], ascending: Bool) -> [FavoriteBook] {
        books.sorted { book1, book2 in
            ascending
                ? book1.title.localizedCaseInsensitiveCompare(book2.title) == .orderedAscending
                : book1.title.localizedCaseInsensitiveCompare(book2.title) == .orderedDescending
        }
    }

    func filterFavorites(_ books: [FavoriteBook], maxPrice: Double) -> [FavoriteBook] {
        // 음수 가격은 필터링하지 않고 전체 반환
        guard maxPrice >= 0 else { return books }

        return books.filter { book in
            guard let price = parsePrice(book.price) else { return true }
            return price <= maxPrice
        }
    }

    // MARK: - Private

    private func isValidISBN13(_ isbn13: String) -> Bool {
        let trimmed = isbn13.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count == 13 && trimmed.allSatisfy { $0.isNumber }
    }

    private func parsePrice(_ priceString: String) -> Double? {
        // "$39.99" -> 39.99
        let cleanedString = priceString
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleanedString)
    }
}
