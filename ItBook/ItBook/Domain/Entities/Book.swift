import Foundation

struct Book: Identifiable, Equatable, Hashable, Sendable {
    let id: String // isbn13
    let title: String
    let subtitle: String
    let price: String
    let imageURL: String
    let url: String

    init(
        isbn13: String,
        title: String,
        subtitle: String = "",
        price: String,
        imageURL: String,
        url: String
    ) {
        self.id = isbn13
        self.title = title
        self.subtitle = subtitle
        self.price = price
        self.imageURL = imageURL
        self.url = url
    }
}

// MARK: - Book Detail (상세 정보)

struct BookDetail: Identifiable, Equatable, Sendable {
    let id: String // isbn13
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
    let imageURL: String
    let url: String
    let pdf: [String: String]?
}

// MARK: - Favorite Book (즐겨찾기 저장용)

struct FavoriteBook: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: String // isbn13
    let title: String
    let subtitle: String
    let authors: String
    let publisher: String
    let imageURL: String
    let price: String
    let year: String?
    let rating: String?
    let addedAt: Date

    init(
        isbn13: String,
        title: String,
        subtitle: String = "",
        authors: String,
        publisher: String,
        imageURL: String,
        price: String,
        year: String? = nil,
        rating: String? = nil,
        addedAt: Date = Date()
    ) {
        self.id = isbn13
        self.title = title
        self.subtitle = subtitle
        self.authors = authors
        self.publisher = publisher
        self.imageURL = imageURL
        self.price = price
        self.year = year
        self.rating = rating
        self.addedAt = addedAt
    }
}
