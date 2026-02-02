import Foundation
import Combine

// MARK: - API Response DTOs

struct NewBooksResponse: Decodable {
    let total: String
    let books: [BookDTO]
}

struct SearchResponse: Decodable {
    let total: String
    let page: String?
    let books: [BookDTO]
}

struct BookDTO: Decodable {
    let title: String
    let subtitle: String
    let isbn13: String
    let price: String
    let image: String
    let url: String
}

struct BookDetailDTO: Decodable {
    let title: String
    let subtitle: String
    let authors: String
    let publisher: String
    let isbn10: String
    let isbn13: String
    let pages: String
    let year: String
    let rating: String
    let desc: String
    let price: String
    let image: String
    let url: String
    let pdf: [String: String]?
}

// MARK: - API Service

protocol ITBookAPIServiceProtocol: Sendable {
    func fetchNewBooks() -> AnyPublisher<NewBooksResponse, Error>
    func searchBooks(query: String, page: Int) -> AnyPublisher<SearchResponse, Error>
    func fetchBookDetail(isbn13: String) -> AnyPublisher<BookDetailDTO, Error>
}

final class ITBookAPIService: ITBookAPIServiceProtocol, @unchecked Sendable {

    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol = NetworkManager()) {
        self.networkManager = networkManager
    }

    func fetchNewBooks() -> AnyPublisher<NewBooksResponse, Error> {
        networkManager.request("/new")
    }

    func searchBooks(query: String, page: Int) -> AnyPublisher<SearchResponse, Error> {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? query
        let endpoint = page > 1 ? "/search/\(encodedQuery)/\(page)" : "/search/\(encodedQuery)"
        return networkManager.request(endpoint)
    }

    func fetchBookDetail(isbn13: String) -> AnyPublisher<BookDetailDTO, Error> {
        networkManager.request("/books/\(isbn13)")
    }
}

// MARK: - DTO to Domain Mapping

extension BookDTO {
    func toDomain() -> Book {
        Book(
            isbn13: isbn13,
            title: title,
            subtitle: subtitle,
            price: price,
            imageURL: image,
            url: url
        )
    }
}

extension BookDetailDTO {
    func toDomain() -> BookDetail {
        BookDetail(
            id: isbn13,
            title: title,
            subtitle: subtitle,
            authors: authors,
            publisher: publisher,
            isbn10: isbn10,
            isbn13: isbn13,
            pages: pages,
            year: year,
            rating: rating,
            desc: desc,
            price: price,
            imageURL: image,
            url: url,
            pdf: pdf
        )
    }

    func toFavoriteBook() -> FavoriteBook {
        FavoriteBook(
            isbn13: isbn13,
            title: title,
            subtitle: subtitle,
            authors: authors,
            publisher: publisher,
            imageURL: image,
            price: price,
            year: year,
            rating: rating
        )
    }
}
