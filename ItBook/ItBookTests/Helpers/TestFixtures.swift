//
//  TestFixtures.swift
//  ItBookTests
//
//  테스트용 고정 데이터
//

import Foundation
@testable import ItBook

// MARK: - Book Fixtures

extension Book {
    static func stub(
        isbn13: String = "9781234567890",
        title: String = "Test Book",
        subtitle: String = "Test Subtitle",
        price: String = "$29.99",
        imageURL: String = "https://example.com/image.png",
        url: String = "https://example.com/book"
    ) -> Book {
        Book(
            isbn13: isbn13,
            title: title,
            subtitle: subtitle,
            price: price,
            imageURL: imageURL,
            url: url
        )
    }

    static func stubList(count: Int = 3) -> [Book] {
        (0..<count).map { index in
            Book.stub(
                isbn13: "978123456789\(index)",
                title: "Test Book \(index)",
                price: "$\(19.99 + Double(index) * 10)"
            )
        }
    }
}

// MARK: - BookDetail Fixtures

extension BookDetail {
    static func stub(
        isbn13: String = "9781234567890",
        title: String = "Test Book Detail",
        subtitle: String = "Detailed Subtitle",
        authors: String = "John Doe",
        publisher: String = "Test Publisher",
        isbn10: String = "1234567890",
        pages: String = "300",
        year: String = "2024",
        rating: String = "4",
        desc: String = "A test book description",
        price: String = "$39.99",
        imageURL: String = "https://example.com/detail.png",
        url: String = "https://example.com/detail",
        pdf: [String: String]? = nil
    ) -> BookDetail {
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
            imageURL: imageURL,
            url: url,
            pdf: pdf
        )
    }
}

// MARK: - FavoriteBook Fixtures

extension FavoriteBook {
    static func stub(
        isbn13: String = "9781234567890",
        title: String = "Favorite Test Book",
        subtitle: String = "Test Subtitle",
        authors: String = "Jane Doe",
        publisher: String = "Favorite Publisher",
        imageURL: String = "https://example.com/favorite.png",
        price: String = "$49.99",
        year: String? = "2024",
        rating: String? = "5",
        addedAt: Date = Date()
    ) -> FavoriteBook {
        FavoriteBook(
            isbn13: isbn13,
            title: title,
            subtitle: subtitle,
            authors: authors,
            publisher: publisher,
            imageURL: imageURL,
            price: price,
            year: year,
            rating: rating,
            addedAt: addedAt
        )
    }

    static func stubList(count: Int = 3) -> [FavoriteBook] {
        (0..<count).map { index in
            FavoriteBook.stub(
                isbn13: "978123456789\(index)",
                title: "Favorite Book \(index)",
                authors: "Author \(index)",
                price: "$\(29.99 + Double(index) * 10)"
            )
        }
    }
}
