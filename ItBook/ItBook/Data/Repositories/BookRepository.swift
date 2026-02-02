import Foundation
import Combine

final class BookRepository: BookRepositoryProtocol, @unchecked Sendable {

    private let apiService: ITBookAPIServiceProtocol

    init(apiService: ITBookAPIServiceProtocol = ITBookAPIService()) {
        self.apiService = apiService
    }

    func fetchNewBooks() -> AnyPublisher<[Book], Error> {
        apiService.fetchNewBooks()
            .map { response in
                response.books.map { $0.toDomain() }
            }
            .eraseToAnyPublisher()
    }

    func searchBooks(query: String, page: Int) -> AnyPublisher<(books: [Book], total: Int), Error> {
        apiService.searchBooks(query: query, page: page)
            .map { response in
                let books = response.books.map { $0.toDomain() }
                let total = Int(response.total) ?? 0
                return (books: books, total: total)
            }
            .eraseToAnyPublisher()
    }

    func fetchBookDetail(isbn13: String) -> AnyPublisher<BookDetail, Error> {
        apiService.fetchBookDetail(isbn13: isbn13)
            .map { $0.toDomain() }
            .eraseToAnyPublisher()
    }
}
