import Foundation
import Combine

// MARK: - Errors

enum SearchBooksError: LocalizedError {
    case emptyQuery
    case invalidQuery(reason: String)
    case invalidISBN13(String)
    case invalidPage(Int)

    var errorDescription: String? {
        switch self {
        case .emptyQuery:
            return "검색어를 입력해주세요"
        case .invalidQuery(let reason):
            return "잘못된 검색어입니다: \(reason)"
        case .invalidISBN13(let isbn):
            return "잘못된 ISBN13입니다: \(isbn)"
        case .invalidPage(let page):
            return "잘못된 페이지 번호입니다: \(page)"
        }
    }
}

// MARK: - Protocol

protocol SearchBooksUseCaseProtocol: Sendable {
    func fetchNewBooks() -> AnyPublisher<[Book], Error>
    func searchBooks(query: String, page: Int) -> AnyPublisher<(books: [Book], total: Int), Error>
    func fetchBookDetail(isbn13: String) -> AnyPublisher<BookDetail, Error>
}

// MARK: - Implementation

final class SearchBooksUseCase: SearchBooksUseCaseProtocol, @unchecked Sendable {

    private let repository: BookRepositoryProtocol
    private let minQueryLength: Int
    private let maxQueryLength: Int

    init(
        repository: BookRepositoryProtocol,
        minQueryLength: Int = 1,
        maxQueryLength: Int = 100
    ) {
        self.repository = repository
        self.minQueryLength = minQueryLength
        self.maxQueryLength = maxQueryLength
    }

    func fetchNewBooks() -> AnyPublisher<[Book], Error> {
        repository.fetchNewBooks()
    }

    func searchBooks(query: String, page: Int) -> AnyPublisher<(books: [Book], total: Int), Error> {
        // 입력 검증
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            return Fail(error: SearchBooksError.emptyQuery).eraseToAnyPublisher()
        }

        guard trimmedQuery.count >= minQueryLength else {
            return Fail(error: SearchBooksError.invalidQuery(reason: "최소 \(minQueryLength)자 이상 입력해주세요"))
                .eraseToAnyPublisher()
        }

        guard trimmedQuery.count <= maxQueryLength else {
            return Fail(error: SearchBooksError.invalidQuery(reason: "최대 \(maxQueryLength)자까지 입력 가능합니다"))
                .eraseToAnyPublisher()
        }

        guard page >= 1 else {
            return Fail(error: SearchBooksError.invalidPage(page)).eraseToAnyPublisher()
        }

        // URL 인코딩 가능한 문자만 허용
        let allowedCharacters = CharacterSet.urlQueryAllowed
        guard trimmedQuery.addingPercentEncoding(withAllowedCharacters: allowedCharacters) != nil else {
            return Fail(error: SearchBooksError.invalidQuery(reason: "검색할 수 없는 문자가 포함되어 있습니다"))
                .eraseToAnyPublisher()
        }

        return repository.searchBooks(query: trimmedQuery, page: page)
    }

    func fetchBookDetail(isbn13: String) -> AnyPublisher<BookDetail, Error> {
        // ISBN13 검증: 13자리 숫자
        let trimmedISBN = isbn13.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedISBN.count == 13 else {
            return Fail(error: SearchBooksError.invalidISBN13(trimmedISBN)).eraseToAnyPublisher()
        }

        guard trimmedISBN.allSatisfy({ $0.isNumber }) else {
            return Fail(error: SearchBooksError.invalidISBN13(trimmedISBN)).eraseToAnyPublisher()
        }

        return repository.fetchBookDetail(isbn13: trimmedISBN)
    }
}
