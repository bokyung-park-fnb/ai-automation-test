//
//  ManageFavoritesUseCaseTests.swift
//  ItBookTests
//
//  ManageFavoritesUseCase TDD 테스트
//  - 즐겨찾기 CRUD 테스트
//  - ISBN13 검증 테스트
//  - 검색/정렬/필터링 비즈니스 로직 테스트
//

import Testing
import Combine
import Foundation
@testable import ItBook

// MARK: - ManageFavoritesUseCase Tests

@Suite("ManageFavoritesUseCase 테스트")
struct ManageFavoritesUseCaseTests {

    // MARK: - Properties

    let mockRepository: MockFavoriteRepository
    let sut: ManageFavoritesUseCase

    // MARK: - Init

    init() {
        mockRepository = MockFavoriteRepository()
        sut = ManageFavoritesUseCase(repository: mockRepository)
    }

    // MARK: - fetchAllFavorites Tests

    @Test("fetchAllFavorites - 모든 즐겨찾기를 가져온다")
    func fetchAllFavorites_returnsFavorites() async throws {
        // Given
        let expectedFavorites = FavoriteBook.stubList(count: 5)
        mockRepository.stubbedFavorites = expectedFavorites

        // When
        let result = try await awaitPublisher(sut.fetchAllFavorites())

        // Then
        #expect(result.count == 5)
        #expect(mockRepository.fetchAllFavoritesCallCount == 1)
    }

    @Test("fetchAllFavorites - 빈 즐겨찾기 목록을 반환한다")
    func fetchAllFavorites_returnsEmptyList() async throws {
        // Given
        mockRepository.stubbedFavorites = []

        // When
        let result = try await awaitPublisher(sut.fetchAllFavorites())

        // Then
        #expect(result.isEmpty)
    }

    // MARK: - addFavorite Tests

    @Test("addFavorite - 즐겨찾기를 추가한다")
    func addFavorite_addsBookToFavorites() async throws {
        // Given
        let book = FavoriteBook.stub()

        // When
        try await awaitPublisher(sut.addFavorite(book))

        // Then
        #expect(mockRepository.addFavoriteCallCount == 1)
        #expect(mockRepository.lastAddedBook == book)
    }

    // MARK: - removeFavorite Tests

    @Test("removeFavorite - 유효한 ISBN13으로 즐겨찾기를 삭제한다")
    func removeFavorite_withValidISBN_removesFavorite() async throws {
        // Given
        let validISBN13 = "9781234567890"

        // When
        try await awaitPublisher(sut.removeFavorite(isbn13: validISBN13))

        // Then
        #expect(mockRepository.removeFavoriteCallCount == 1)
        #expect(mockRepository.lastRemovedISBN13 == validISBN13)
    }

    @Test("removeFavorite - 잘못된 ISBN13은 에러를 반환한다",
          arguments: ["123", "12345678901234", "", "978123456789X"])
    func removeFavorite_withInvalidISBN_throwsError(isbn13: String) async {
        // When / Then
        await #expect(throws: FavoritesError.self) {
            try await awaitPublisher(sut.removeFavorite(isbn13: isbn13))
        }
        #expect(mockRepository.removeFavoriteCallCount == 0)
    }

    // MARK: - isFavorite Tests

    @Test("isFavorite - 유효한 ISBN13으로 즐겨찾기 여부를 확인한다")
    func isFavorite_withValidISBN_returnsStatus() async throws {
        // Given
        let validISBN13 = "9781234567890"
        mockRepository.stubbedIsFavorite = true

        // When
        let result = try await awaitPublisher(sut.isFavorite(isbn13: validISBN13))

        // Then
        #expect(result == true)
        #expect(mockRepository.isFavoriteCallCount == 1)
        #expect(mockRepository.lastCheckedISBN13 == validISBN13)
    }

    @Test("isFavorite - 잘못된 ISBN13은 에러를 반환한다",
          arguments: ["123", "97812345678ab", "  "])
    func isFavorite_withInvalidISBN_throwsError(isbn13: String) async {
        // When / Then
        await #expect(throws: FavoritesError.self) {
            try await awaitPublisher(sut.isFavorite(isbn13: isbn13))
        }
        #expect(mockRepository.isFavoriteCallCount == 0)
    }

    // MARK: - toggleFavorite Tests

    @Test("toggleFavorite - 즐겨찾기를 토글한다")
    func toggleFavorite_togglesFavoriteStatus() async throws {
        // Given
        let book = FavoriteBook.stub()
        mockRepository.stubbedToggleResult = true

        // When
        let result = try await awaitPublisher(sut.toggleFavorite(book))

        // Then
        #expect(result == true)
        #expect(mockRepository.toggleFavoriteCallCount == 1)
        #expect(mockRepository.lastToggledBook == book)
    }

    // MARK: - searchFavorites Tests (로컬 검색 비즈니스 로직)

    @Test("searchFavorites - 제목으로 검색한다")
    func searchFavorites_byTitle_returnsMatchingBooks() async throws {
        // Given
        let books = [
            FavoriteBook.stub(isbn13: "9781234567890", title: "Swift Programming"),
            FavoriteBook.stub(isbn13: "9781234567891", title: "iOS Development"),
            FavoriteBook.stub(isbn13: "9781234567892", title: "Advanced Swift")
        ]
        mockRepository.stubbedFavorites = books

        // When
        let result = try await awaitPublisher(sut.searchFavorites(query: "Swift"))

        // Then
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.title.lowercased().contains("swift") })
    }

    @Test("searchFavorites - 저자로 검색한다")
    func searchFavorites_byAuthor_returnsMatchingBooks() async throws {
        // Given
        let books = [
            FavoriteBook.stub(isbn13: "9781234567890", title: "Book 1", authors: "John Doe"),
            FavoriteBook.stub(isbn13: "9781234567891", title: "Book 2", authors: "Jane Smith"),
            FavoriteBook.stub(isbn13: "9781234567892", title: "Book 3", authors: "John Adams")
        ]
        mockRepository.stubbedFavorites = books

        // When
        let result = try await awaitPublisher(sut.searchFavorites(query: "John"))

        // Then
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.authors.lowercased().contains("john") })
    }

    @Test("searchFavorites - 대소문자를 구분하지 않고 검색한다")
    func searchFavorites_isCaseInsensitive() async throws {
        // Given
        let books = [
            FavoriteBook.stub(isbn13: "9781234567890", title: "SWIFT Programming"),
            FavoriteBook.stub(isbn13: "9781234567891", title: "swift guide")
        ]
        mockRepository.stubbedFavorites = books

        // When
        let result = try await awaitPublisher(sut.searchFavorites(query: "Swift"))

        // Then
        #expect(result.count == 2)
    }

    @Test("searchFavorites - 빈 검색어는 모든 즐겨찾기를 반환한다")
    func searchFavorites_withEmptyQuery_returnsAllBooks() async throws {
        // Given
        let books = FavoriteBook.stubList(count: 5)
        mockRepository.stubbedFavorites = books

        // When
        let result = try await awaitPublisher(sut.searchFavorites(query: ""))

        // Then
        #expect(result.count == 5)
    }

    @Test("searchFavorites - 일치하는 결과가 없으면 빈 배열을 반환한다")
    func searchFavorites_withNoMatch_returnsEmptyArray() async throws {
        // Given
        let books = [
            FavoriteBook.stub(isbn13: "9781234567890", title: "iOS Book", authors: "Author A")
        ]
        mockRepository.stubbedFavorites = books

        // When
        let result = try await awaitPublisher(sut.searchFavorites(query: "Android"))

        // Then
        #expect(result.isEmpty)
    }

    // MARK: - sortFavorites Tests (정렬 비즈니스 로직)

    @Test("sortFavorites - 제목 오름차순 정렬")
    func sortFavorites_ascending_sortsByTitleAsc() {
        // Given
        let books = [
            FavoriteBook.stub(isbn13: "9781234567890", title: "Zebra"),
            FavoriteBook.stub(isbn13: "9781234567891", title: "Apple"),
            FavoriteBook.stub(isbn13: "9781234567892", title: "Mango")
        ]

        // When
        let sorted = sut.sortFavorites(books, ascending: true)

        // Then
        #expect(sorted[0].title == "Apple")
        #expect(sorted[1].title == "Mango")
        #expect(sorted[2].title == "Zebra")
    }

    @Test("sortFavorites - 제목 내림차순 정렬")
    func sortFavorites_descending_sortsByTitleDesc() {
        // Given
        let books = [
            FavoriteBook.stub(isbn13: "9781234567890", title: "Apple"),
            FavoriteBook.stub(isbn13: "9781234567891", title: "Zebra"),
            FavoriteBook.stub(isbn13: "9781234567892", title: "Mango")
        ]

        // When
        let sorted = sut.sortFavorites(books, ascending: false)

        // Then
        #expect(sorted[0].title == "Zebra")
        #expect(sorted[1].title == "Mango")
        #expect(sorted[2].title == "Apple")
    }

    @Test("sortFavorites - 대소문자를 구분하지 않고 정렬한다")
    func sortFavorites_isCaseInsensitive() {
        // Given
        let books = [
            FavoriteBook.stub(isbn13: "9781234567890", title: "zebra"),
            FavoriteBook.stub(isbn13: "9781234567891", title: "Apple"),
            FavoriteBook.stub(isbn13: "9781234567892", title: "BANANA")
        ]

        // When
        let sorted = sut.sortFavorites(books, ascending: true)

        // Then
        #expect(sorted[0].title == "Apple")
        #expect(sorted[1].title == "BANANA")
        #expect(sorted[2].title == "zebra")
    }

    @Test("sortFavorites - 빈 배열은 빈 배열을 반환한다")
    func sortFavorites_emptyArray_returnsEmptyArray() {
        // Given
        let books: [FavoriteBook] = []

        // When
        let sorted = sut.sortFavorites(books, ascending: true)

        // Then
        #expect(sorted.isEmpty)
    }

    // MARK: - filterFavorites Tests (필터링 비즈니스 로직)

    @Test("filterFavorites - 최대 가격 이하의 도서만 반환한다")
    func filterFavorites_byMaxPrice_returnsFilteredBooks() {
        // Given
        let books = [
            FavoriteBook.stub(isbn13: "9781234567890", price: "$19.99"),
            FavoriteBook.stub(isbn13: "9781234567891", price: "$29.99"),
            FavoriteBook.stub(isbn13: "9781234567892", price: "$49.99"),
            FavoriteBook.stub(isbn13: "9781234567893", price: "$99.99")
        ]

        // When
        let filtered = sut.filterFavorites(books, maxPrice: 30.0)

        // Then
        #expect(filtered.count == 2)
        // $19.99와 $29.99만 포함
    }

    @Test("filterFavorites - 정확히 최대 가격인 도서도 포함한다")
    func filterFavorites_includesExactMaxPrice() {
        // Given
        let books = [
            FavoriteBook.stub(isbn13: "9781234567890", price: "$30.00")
        ]

        // When
        let filtered = sut.filterFavorites(books, maxPrice: 30.0)

        // Then
        #expect(filtered.count == 1)
    }

    @Test("filterFavorites - 음수 최대 가격은 모든 도서를 반환한다")
    func filterFavorites_withNegativeMaxPrice_returnsAllBooks() {
        // Given
        let books = FavoriteBook.stubList(count: 3)

        // When
        let filtered = sut.filterFavorites(books, maxPrice: -1.0)

        // Then
        #expect(filtered.count == 3)
    }

    @Test("filterFavorites - 0 최대 가격은 무료 도서만 반환한다")
    func filterFavorites_withZeroMaxPrice_returnsFreeBooks() {
        // Given
        let books = [
            FavoriteBook.stub(isbn13: "9781234567890", price: "$0.00"),
            FavoriteBook.stub(isbn13: "9781234567891", price: "$19.99")
        ]

        // When
        let filtered = sut.filterFavorites(books, maxPrice: 0.0)

        // Then
        #expect(filtered.count == 1)
        #expect(filtered[0].price == "$0.00")
    }

    @Test("filterFavorites - 파싱할 수 없는 가격은 필터링하지 않는다")
    func filterFavorites_withUnparsablePrice_includesBook() {
        // Given
        let books = [
            FavoriteBook.stub(isbn13: "9781234567890", price: "Free"),
            FavoriteBook.stub(isbn13: "9781234567891", price: "N/A"),
            FavoriteBook.stub(isbn13: "9781234567892", price: "$19.99")
        ]

        // When
        let filtered = sut.filterFavorites(books, maxPrice: 10.0)

        // Then
        // "Free"와 "N/A"는 파싱 실패 -> 포함, "$19.99"는 10보다 큼 -> 제외
        #expect(filtered.count == 2)
    }

    @Test("filterFavorites - 쉼표가 포함된 가격을 파싱한다")
    func filterFavorites_parsesCommaInPrice() {
        // Given
        let books = [
            FavoriteBook.stub(isbn13: "9781234567890", price: "$1,234.99")
        ]

        // When
        let filtered = sut.filterFavorites(books, maxPrice: 1500.0)

        // Then
        #expect(filtered.count == 1)
    }
}

// MARK: - Helper Extension

private func awaitPublisher<T>(_ publisher: AnyPublisher<T, Error>) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
        var cancellable: AnyCancellable?
        cancellable = publisher
            .first()
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                },
                receiveValue: { value in
                    continuation.resume(returning: value)
                }
            )
    }
}

private func awaitPublisher(_ publisher: AnyPublisher<Void, Error>) async throws {
    try await withCheckedThrowingContinuation { continuation in
        var cancellable: AnyCancellable?
        cancellable = publisher
            .first()
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                },
                receiveValue: { _ in }
            )
    }
}
