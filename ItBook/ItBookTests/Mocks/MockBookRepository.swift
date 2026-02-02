//
//  MockBookRepository.swift
//  ItBookTests
//
//  Mock Repository for SearchBooksUseCase 테스트
//

import Foundation
import Combine
@testable import ItBook

// MARK: - MockBookRepository

final class MockBookRepository: BookRepositoryProtocol, @unchecked Sendable {

    // MARK: - Stub Data

    var stubbedNewBooks: [Book] = []
    var stubbedSearchResult: (books: [Book], total: Int) = ([], 0)
    var stubbedBookDetail: BookDetail?
    var stubbedError: Error?

    // MARK: - Call Tracking

    private(set) var fetchNewBooksCallCount = 0
    private(set) var searchBooksCallCount = 0
    private(set) var fetchBookDetailCallCount = 0
    private(set) var lastSearchQuery: String?
    private(set) var lastSearchPage: Int?
    private(set) var lastISBN13: String?

    // MARK: - BookRepositoryProtocol

    func fetchNewBooks() -> AnyPublisher<[Book], Error> {
        fetchNewBooksCallCount += 1

        if let error = stubbedError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return Just(stubbedNewBooks)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func searchBooks(query: String, page: Int) -> AnyPublisher<(books: [Book], total: Int), Error> {
        searchBooksCallCount += 1
        lastSearchQuery = query
        lastSearchPage = page

        if let error = stubbedError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return Just(stubbedSearchResult)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func fetchBookDetail(isbn13: String) -> AnyPublisher<BookDetail, Error> {
        fetchBookDetailCallCount += 1
        lastISBN13 = isbn13

        if let error = stubbedError {
            return Fail(error: error).eraseToAnyPublisher()
        }

        guard let detail = stubbedBookDetail else {
            return Fail(error: NSError(domain: "MockError", code: -1))
                .eraseToAnyPublisher()
        }

        return Just(detail)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    // MARK: - Reset

    func reset() {
        stubbedNewBooks = []
        stubbedSearchResult = ([], 0)
        stubbedBookDetail = nil
        stubbedError = nil
        fetchNewBooksCallCount = 0
        searchBooksCallCount = 0
        fetchBookDetailCallCount = 0
        lastSearchQuery = nil
        lastSearchPage = nil
        lastISBN13 = nil
    }
}
