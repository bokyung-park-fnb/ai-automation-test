import Foundation
import Combine

final class FavoriteRepository: FavoriteRepositoryProtocol, @unchecked Sendable {

    private let storage: FavoriteStorageProtocol

    init(storage: FavoriteStorageProtocol = FavoriteStorage()) {
        self.storage = storage
    }

    func fetchAllFavorites() -> AnyPublisher<[FavoriteBook], Error> {
        Just(storage.fetchAll())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func addFavorite(_ book: FavoriteBook) -> AnyPublisher<Void, Error> {
        Just(storage.save(book))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func removeFavorite(isbn13: String) -> AnyPublisher<Void, Error> {
        Just(storage.delete(isbn13: isbn13))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func isFavorite(isbn13: String) -> AnyPublisher<Bool, Error> {
        Just(storage.exists(isbn13: isbn13))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func toggleFavorite(_ book: FavoriteBook) -> AnyPublisher<Bool, Error> {
        let exists = storage.exists(isbn13: book.id)

        if exists {
            storage.delete(isbn13: book.id)
        } else {
            storage.save(book)
        }

        return Just(!exists)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
