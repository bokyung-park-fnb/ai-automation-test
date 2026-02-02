//
//  SearchBooksUseCaseTests.swift
//  ItBookTests
//
//  SearchBooksUseCase TDD 테스트
//  - 입력 검증 로직 테스트
//  - ISBN13 검증 테스트
//  - 페이지 번호 검증 테스트
//

import Testing
import Combine
import Foundation
@testable import ItBook

// MARK: - SearchBooksUseCase Tests

@Suite("SearchBooksUseCase 테스트")
struct SearchBooksUseCaseTests {

    // MARK: - Properties

    let mockRepository: MockBookRepository
    let sut: SearchBooksUseCase

    // MARK: - Init (setUp 대체)

    init() {
        mockRepository = MockBookRepository()
        sut = SearchBooksUseCase(repository: mockRepository)
    }

    // MARK: - fetchNewBooks Tests

    @Test("fetchNewBooks - 새 도서 목록을 정상적으로 가져온다")
    func fetchNewBooks_returnsBooks() async throws {
        // Given
        let expectedBooks = Book.stubList(count: 3)
        mockRepository.stubbedNewBooks = expectedBooks

        // When
        let result = try await awaitPublisher(sut.fetchNewBooks())

        // Then
        #expect(result.count == 3)
        #expect(mockRepository.fetchNewBooksCallCount == 1)
    }

    @Test("fetchNewBooks - Repository 에러 발생 시 에러를 전달한다")
    func fetchNewBooks_propagatesError() async {
        // Given
        let expectedError = NSError(domain: "TestError", code: -1)
        mockRepository.stubbedError = expectedError

        // When / Then
        await #expect(throws: Error.self) {
            try await awaitPublisher(sut.fetchNewBooks())
        }
    }

    // MARK: - searchBooks Query Validation Tests

    @Test("searchBooks - 빈 검색어는 emptyQuery 에러를 반환한다")
    func searchBooks_withEmptyQuery_throwsEmptyQueryError() async {
        // Given
        let emptyQuery = ""

        // When / Then
        await #expect(throws: SearchBooksError.self) {
            try await awaitPublisher(sut.searchBooks(query: emptyQuery, page: 1))
        }
    }

    @Test("searchBooks - 공백만 있는 검색어는 emptyQuery 에러를 반환한다")
    func searchBooks_withWhitespaceOnlyQuery_throwsEmptyQueryError() async {
        // Given
        let whitespaceQuery = "   \n\t  "

        // When / Then
        await #expect(throws: SearchBooksError.self) {
            try await awaitPublisher(sut.searchBooks(query: whitespaceQuery, page: 1))
        }
    }

    @Test("searchBooks - 유효한 검색어로 도서를 검색한다",
          arguments: ["Swift", "iOS", "Programming", "한글검색어"])
    func searchBooks_withValidQuery_returnsBooks(query: String) async throws {
        // Given
        let expectedBooks = Book.stubList(count: 5)
        mockRepository.stubbedSearchResult = (books: expectedBooks, total: 100)

        // When
        let result = try await awaitPublisher(sut.searchBooks(query: query, page: 1))

        // Then
        #expect(result.books.count == 5)
        #expect(result.total == 100)
        #expect(mockRepository.searchBooksCallCount == 1)
        #expect(mockRepository.lastSearchQuery == query)
    }

    @Test("searchBooks - 검색어 앞뒤 공백을 제거한다")
    func searchBooks_trimsQuery() async throws {
        // Given
        let queryWithSpaces = "  Swift Programming  "
        mockRepository.stubbedSearchResult = (books: [], total: 0)

        // When
        _ = try await awaitPublisher(sut.searchBooks(query: queryWithSpaces, page: 1))

        // Then
        #expect(mockRepository.lastSearchQuery == "Swift Programming")
    }

    // MARK: - searchBooks Query Length Validation Tests

    @Test("searchBooks - 최대 길이 초과 검색어는 invalidQuery 에러를 반환한다")
    func searchBooks_withTooLongQuery_throwsInvalidQueryError() async {
        // Given
        let customSut = SearchBooksUseCase(
            repository: mockRepository,
            minQueryLength: 1,
            maxQueryLength: 10
        )
        let longQuery = String(repeating: "a", count: 11)

        // When / Then
        await #expect(throws: SearchBooksError.self) {
            try await awaitPublisher(customSut.searchBooks(query: longQuery, page: 1))
        }
    }

    @Test("searchBooks - 최소 길이 미만 검색어는 invalidQuery 에러를 반환한다")
    func searchBooks_withTooShortQuery_throwsInvalidQueryError() async {
        // Given
        let customSut = SearchBooksUseCase(
            repository: mockRepository,
            minQueryLength: 3,
            maxQueryLength: 100
        )
        let shortQuery = "ab"

        // When / Then
        await #expect(throws: SearchBooksError.self) {
            try await awaitPublisher(customSut.searchBooks(query: shortQuery, page: 1))
        }
    }

    // MARK: - searchBooks Page Validation Tests

    @Test("searchBooks - 페이지 번호가 0 이하면 invalidPage 에러를 반환한다",
          arguments: [0, -1, -100])
    func searchBooks_withInvalidPage_throwsInvalidPageError(page: Int) async {
        // Given
        let validQuery = "Swift"

        // When / Then
        await #expect(throws: SearchBooksError.self) {
            try await awaitPublisher(sut.searchBooks(query: validQuery, page: page))
        }
    }

    @Test("searchBooks - 유효한 페이지 번호로 검색한다",
          arguments: [1, 2, 10, 100])
    func searchBooks_withValidPage_returnsBooks(page: Int) async throws {
        // Given
        mockRepository.stubbedSearchResult = (books: Book.stubList(), total: 100)

        // When
        _ = try await awaitPublisher(sut.searchBooks(query: "Swift", page: page))

        // Then
        #expect(mockRepository.lastSearchPage == page)
    }

    // MARK: - fetchBookDetail ISBN13 Validation Tests

    @Test("fetchBookDetail - 유효한 ISBN13으로 상세 정보를 가져온다")
    func fetchBookDetail_withValidISBN13_returnsDetail() async throws {
        // Given
        let validISBN13 = "9781234567890"
        let expectedDetail = BookDetail.stub(isbn13: validISBN13)
        mockRepository.stubbedBookDetail = expectedDetail

        // When
        let result = try await awaitPublisher(sut.fetchBookDetail(isbn13: validISBN13))

        // Then
        #expect(result.isbn13 == validISBN13)
        #expect(mockRepository.fetchBookDetailCallCount == 1)
        #expect(mockRepository.lastISBN13 == validISBN13)
    }

    @Test("fetchBookDetail - ISBN13이 13자리가 아니면 에러를 반환한다",
          arguments: ["123", "12345678901234", ""])
    func fetchBookDetail_withWrongLengthISBN_throwsError(isbn13: String) async {
        // When / Then
        await #expect(throws: SearchBooksError.self) {
            try await awaitPublisher(sut.fetchBookDetail(isbn13: isbn13))
        }
    }

    @Test("fetchBookDetail - ISBN13에 숫자가 아닌 문자가 있으면 에러를 반환한다",
          arguments: ["978123456789X", "97812345678ab", "978-123456789"])
    func fetchBookDetail_withNonNumericISBN_throwsError(isbn13: String) async {
        // When / Then
        await #expect(throws: SearchBooksError.self) {
            try await awaitPublisher(sut.fetchBookDetail(isbn13: isbn13))
        }
    }

    @Test("fetchBookDetail - ISBN13 앞뒤 공백을 제거하고 검증한다")
    func fetchBookDetail_trimsISBN13() async throws {
        // Given
        let isbn13WithSpaces = "  9781234567890  "
        mockRepository.stubbedBookDetail = BookDetail.stub()

        // When
        _ = try await awaitPublisher(sut.fetchBookDetail(isbn13: isbn13WithSpaces))

        // Then
        #expect(mockRepository.lastISBN13 == "9781234567890")
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
