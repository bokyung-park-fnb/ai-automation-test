//
//  MockFavoriteRepository.swift
//  ItBookTests
//
//  Mock Repository for ManageFavoritesUseCase 테스트
//

import Foundation
import Combine
@testable import ItBook

// MARK: - MockFavoriteRepository

final class MockFavoriteRepository: FavoriteRepositoryProtocol, @unchecked Sendable {

    // MARK: - Stub Data

    var stubbedFavorites: [FavoriteBook] = []
    var stubbedIsFavorite: Bool = false
    var stubbedToggleResult: Bool = true
    var stubbedError: Error?

    // MARK: - Call Tracking

    private(set) var fetchAllFavoritesCallCount = 0
    private(set) var addFavoriteCallCount = 0
    private(set) var removeFavoriteCallCount = 0
    private(set) var isFavoriteCallCount = 0
    private(set) var toggleFavoriteCallCount = 0
    private(set) var lastAddedBook: FavoriteBook?
    private(set) var lastRemovedISBN13: String?
    private(set) var lastCheckedISBN13: String?
    private(set) var lastToggledBook: FavoriteBook?

    // MARK: - FavoriteRepositoryProtocol

    func fetchAllFavorites() -> AnyPublisher<[FavoriteBook], Error> {
        fetchAllFavoritesCallCount += 1

        if let error = stubbedError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return Just(stubbedFavorites)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
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

    // MARK: - Reset

    func reset() {
        stubbedFavorites = []
        stubbedIsFavorite = false
        stubbedToggleResult = true
        stubbedError = nil
        fetchAllFavoritesCallCount = 0
        addFavoriteCallCount = 0
        removeFavoriteCallCount = 0
        isFavoriteCallCount = 0
        toggleFavoriteCallCount = 0
        lastAddedBook = nil
        lastRemovedISBN13 = nil
        lastCheckedISBN13 = nil
        lastToggledBook = nil
    }
}
