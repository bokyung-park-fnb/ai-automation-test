//
//  MockUseCases.swift
//  ItBookTests
//
//  Mock UseCases for ViewModel testing
//

import Foundation
import Combine
@testable import ItBook

// MARK: - MockSearchBooksUseCase

final class MockSearchBooksUseCase: SearchBooksUseCaseProtocol, @unchecked Sendable {

    // MARK: - Stub Data

    var stubbedNewBooks: [Book] = []
    var stubbedSearchResult: (books: [Book], total: Int) = ([], 0)
    var stubbedBookDetail: BookDetail?
    var stubbedError: Error?

    // Delay simulation (in seconds)
    var delay: TimeInterval = 0

    // MARK: - Call Tracking

    private(set) var fetchNewBooksCallCount = 0
    private(set) var searchBooksCallCount = 0
    private(set) var fetchBookDetailCallCount = 0
    private(set) var lastSearchQuery: String?
    private(set) var lastSearchPage: Int?
    private(set) var lastISBN13: String?

    // MARK: - SearchBooksUseCaseProtocol

    func fetchNewBooks() -> AnyPublisher<[Book], Error> {
        fetchNewBooksCallCount += 1

        let publisher: AnyPublisher<[Book], Error>
        if let error = stubbedError {
            publisher = Fail(error: error).eraseToAnyPublisher()
        } else {
            publisher = Just(stubbedNewBooks)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        if delay > 0 {
            return publisher
                .delay(for: .seconds(delay), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        return publisher
    }

    func searchBooks(query: String, page: Int) -> AnyPublisher<(books: [Book], total: Int), Error> {
        searchBooksCallCount += 1
        lastSearchQuery = query
        lastSearchPage = page

        let publisher: AnyPublisher<(books: [Book], total: Int), Error>
        if let error = stubbedError {
            publisher = Fail(error: error).eraseToAnyPublisher()
        } else {
            publisher = Just(stubbedSearchResult)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        if delay > 0 {
            return publisher
                .delay(for: .seconds(delay), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        return publisher
    }

    func fetchBookDetail(isbn13: String) -> AnyPublisher<BookDetail, Error> {
        fetchBookDetailCallCount += 1
        lastISBN13 = isbn13

        let publisher: AnyPublisher<BookDetail, Error>
        if let error = stubbedError {
            publisher = Fail(error: error).eraseToAnyPublisher()
        } else if let detail = stubbedBookDetail {
            publisher = Just(detail)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            publisher = Fail(error: NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No stubbed detail"]))
                .eraseToAnyPublisher()
        }

        if delay > 0 {
            return publisher
                .delay(for: .seconds(delay), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        return publisher
    }

    // MARK: - Reset

    func reset() {
        stubbedNewBooks = []
        stubbedSearchResult = ([], 0)
        stubbedBookDetail = nil
        stubbedError = nil
        delay = 0
        fetchNewBooksCallCount = 0
        searchBooksCallCount = 0
        fetchBookDetailCallCount = 0
        lastSearchQuery = nil
        lastSearchPage = nil
        lastISBN13 = nil
    }
}

// MARK: - MockManageFavoritesUseCase

final class MockManageFavoritesUseCase: ManageFavoritesUseCaseProtocol, @unchecked Sendable {

    // MARK: - Stub Data

    var stubbedFavorites: [FavoriteBook] = []
    var stubbedIsFavorite: Bool = false
    var stubbedToggleResult: Bool = true
    var stubbedSearchResult: [FavoriteBook] = []
    var stubbedError: Error?

    // Delay simulation (in seconds)
    var delay: TimeInterval = 0

    // MARK: - Call Tracking

    private(set) var fetchAllFavoritesCallCount = 0
    private(set) var addFavoriteCallCount = 0
    private(set) var removeFavoriteCallCount = 0
    private(set) var isFavoriteCallCount = 0
    private(set) var toggleFavoriteCallCount = 0
    private(set) var searchFavoritesCallCount = 0
    private(set) var sortFavoritesCallCount = 0
    private(set) var filterFavoritesCallCount = 0

    private(set) var lastAddedBook: FavoriteBook?
    private(set) var lastRemovedISBN13: String?
    private(set) var lastCheckedISBN13: String?
    private(set) var lastToggledBook: FavoriteBook?
    private(set) var lastSearchQuery: String?
    private(set) var lastSortAscending: Bool?
    private(set) var lastFilterMaxPrice: Double?

    // MARK: - ManageFavoritesUseCaseProtocol

    func fetchAllFavorites() -> AnyPublisher<[FavoriteBook], Error> {
        fetchAllFavoritesCallCount += 1

        let publisher: AnyPublisher<[FavoriteBook], Error>
        if let error = stubbedError {
            publisher = Fail(error: error).eraseToAnyPublisher()
        } else {
            publisher = Just(stubbedFavorites)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        if delay > 0 {
            return publisher
                .delay(for: .seconds(delay), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        return publisher
    }

    func addFavorite(_ book: FavoriteBook) -> AnyPublisher<Void, Error> {
        addFavoriteCallCount += 1
        lastAddedBook = book

        if let error = stubbedError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func removeFavorite(isbn13: String) -> AnyPublisher<Void, Error> {
        removeFavoriteCallCount += 1
        lastRemovedISBN13 = isbn13

        if let error = stubbedError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func isFavorite(isbn13: String) -> AnyPublisher<Bool, Error> {
        isFavoriteCallCount += 1
        lastCheckedISBN13 = isbn13

        if let error = stubbedError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return Just(stubbedIsFavorite)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func toggleFavorite(_ book: FavoriteBook) -> AnyPublisher<Bool, Error> {
        toggleFavoriteCallCount += 1
        lastToggledBook = book

        if let error = stubbedError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return Just(stubbedToggleResult)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func searchFavorites(query: String) -> AnyPublisher<[FavoriteBook], Error> {
        searchFavoritesCallCount += 1
        lastSearchQuery = query

        if let error = stubbedError {
            return Fail(error: error).eraseToAnyPublisher()
        }

        // Use stubbed search result or filter from favorites
        if !stubbedSearchResult.isEmpty {
            return Just(stubbedSearchResult)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        // Default: filter from stubbedFavorites
        let filtered = query.isEmpty ? stubbedFavorites : stubbedFavorites.filter {
            $0.title.lowercased().contains(query.lowercased()) ||
            $0.authors.lowercased().contains(query.lowercased())
        }
        return Just(filtered)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func sortFavorites(_ books: [FavoriteBook], ascending: Bool) -> [FavoriteBook] {
        sortFavoritesCallCount += 1
        lastSortAscending = ascending

        return books.sorted { book1, book2 in
            ascending
                ? book1.title.localizedCaseInsensitiveCompare(book2.title) == .orderedAscending
                : book1.title.localizedCaseInsensitiveCompare(book2.title) == .orderedDescending
        }
    }

    func filterFavorites(_ books: [FavoriteBook], maxPrice: Double) -> [FavoriteBook] {
        filterFavoritesCallCount += 1
        lastFilterMaxPrice = maxPrice

        guard maxPrice >= 0 else { return books }

        return books.filter { book in
            guard let price = parsePrice(book.price) else { return true }
            return price <= maxPrice
        }
    }

    // MARK: - Private

    private func parsePrice(_ priceString: String) -> Double? {
        let cleanedString = priceString
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleanedString)
    }

    // MARK: - Reset

    func reset() {
        stubbedFavorites = []
        stubbedIsFavorite = false
        stubbedToggleResult = true
        stubbedSearchResult = []
        stubbedError = nil
        delay = 0

        fetchAllFavoritesCallCount = 0
        addFavoriteCallCount = 0
        removeFavoriteCallCount = 0
        isFavoriteCallCount = 0
        toggleFavoriteCallCount = 0
        searchFavoritesCallCount = 0
        sortFavoritesCallCount = 0
        filterFavoritesCallCount = 0

        lastAddedBook = nil
        lastRemovedISBN13 = nil
        lastCheckedISBN13 = nil
        lastToggledBook = nil
        lastSearchQuery = nil
        lastSortAscending = nil
        lastFilterMaxPrice = nil
    }
}
