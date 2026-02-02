import Foundation
import Combine

protocol FavoriteStorageProtocol: Sendable {
    func fetchAll() -> [FavoriteBook]
    func save(_ book: FavoriteBook)
    func delete(isbn13: String)
    func exists(isbn13: String) -> Bool
}

final class FavoriteStorage: FavoriteStorageProtocol, @unchecked Sendable {

    private let userDefaults: UserDefaults
    private let key = "favorite_books"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func fetchAll() -> [FavoriteBook] {
        guard let data = userDefaults.data(forKey: key) else {
            return []
        }

        do {
            let books = try JSONDecoder().decode([FavoriteBook].self, from: data)
            return books.sorted { $0.addedAt > $1.addedAt }
        } catch {
            return []
        }
    }

    func save(_ book: FavoriteBook) {
        var books = fetchAll()

        // 중복 체크
        if let index = books.firstIndex(where: { $0.id == book.id }) {
            books[index] = book
        } else {
            books.insert(book, at: 0)
        }

        saveAll(books)
    }

    func delete(isbn13: String) {
        var books = fetchAll()
        books.removeAll { $0.id == isbn13 }
        saveAll(books)
    }

    func exists(isbn13: String) -> Bool {
        fetchAll().contains { $0.id == isbn13 }
    }

    // MARK: - Private

    private func saveAll(_ books: [FavoriteBook]) {
        do {
            let data = try JSONEncoder().encode(books)
            userDefaults.set(data, forKey: key)
        } catch {
            // Handle encoding error silently
        }
    }
}
