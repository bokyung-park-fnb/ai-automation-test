//
//  BookDetailViewModelTests.swift
//  ItBookTests
//
//  BookDetailViewModel TDD tests
//  - loadBookDetail tests
//  - toggleFavorite tests
//  - State change tests
//  - Error handling tests
//

import Testing
import Combine
import Foundation
@testable import ItBook

// MARK: - BookDetailViewModel Tests

@Suite("BookDetailViewModel Tests")
struct BookDetailViewModelTests {

    // MARK: - Properties

    let mockSearchBooksUseCase: MockSearchBooksUseCase
    let mockFavoritesUseCase: MockManageFavoritesUseCase

    // MARK: - Init

    init() {
        mockSearchBooksUseCase = MockSearchBooksUseCase()
        mockFavoritesUseCase = MockManageFavoritesUseCase()
    }

    // MARK: - Factory

    private func makeSUT(isbn13: String = "9781234567890") -> BookDetailViewModel {
        BookDetailViewModel(
            isbn13: isbn13,
            searchBooksUseCase: mockSearchBooksUseCase,
            favoritesUseCase: mockFavoritesUseCase
        )
    }

    // MARK: - Initialization Tests

    @Test("init stores isbn13 correctly")
    func init_storesISBN13() {
        // Given
        let isbn13 = "9789876543210"

        // When
        let sut = makeSUT(isbn13: isbn13)

        // Then
        #expect(sut.isbn13 == isbn13)
    }

    @Test("init sets initial state correctly")
    func init_setsInitialState() {
        // When
        let sut = makeSUT()

        // Then
        #expect(sut.bookDetail == nil)
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
        #expect(sut.isFavorite == false)
    }

    // MARK: - loadBookDetail Tests

    @Test("loadBookDetail sets isLoading to true")
    func loadBookDetail_setsLoadingTrue() async {
        // Given
        mockSearchBooksUseCase.stubbedBookDetail = BookDetail.stub()
        mockSearchBooksUseCase.delay = 0.5 // Add delay to keep loading state
        mockFavoritesUseCase.stubbedIsFavorite = false
        let sut = makeSUT()

        // When
        sut.loadBookDetail()

        // Then - check loading state while delayed
        #expect(sut.isLoading == true)

        // Wait for async completion
        await waitForPublisher(timeout: 1.0)
    }

    @Test("loadBookDetail clears previous error message")
    func loadBookDetail_clearsErrorMessage() async {
        // Given
        mockSearchBooksUseCase.stubbedBookDetail = BookDetail.stub()
        let sut = makeSUT()

        // Simulate previous error state (via failed load)
        mockSearchBooksUseCase.stubbedError = NSError(domain: "Test", code: -1)
        sut.loadBookDetail()
        await waitForPublisher(timeout: 0.2)

        // Reset for successful load
        mockSearchBooksUseCase.stubbedError = nil

        // When
        sut.loadBookDetail()

        // Then
        #expect(sut.errorMessage == nil)

        await waitForPublisher(timeout: 0.5)
    }

    @Test("loadBookDetail updates bookDetail on success")
    func loadBookDetail_updatesBookDetailOnSuccess() async {
        // Given
        let expectedDetail = BookDetail.stub(
            isbn13: "9781234567890",
            title: "Swift Programming"
        )
        mockSearchBooksUseCase.stubbedBookDetail = expectedDetail
        mockFavoritesUseCase.stubbedIsFavorite = false
        let sut = makeSUT()

        // When
        sut.loadBookDetail()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.bookDetail != nil)
        #expect(sut.bookDetail?.title == "Swift Programming")
        #expect(sut.isLoading == false)
    }

    @Test("loadBookDetail checks favorite status on success")
    func loadBookDetail_checksFavoriteStatusOnSuccess() async {
        // Given
        mockSearchBooksUseCase.stubbedBookDetail = BookDetail.stub()
        mockFavoritesUseCase.stubbedIsFavorite = true
        let sut = makeSUT(isbn13: "9781234567890")

        // When
        sut.loadBookDetail()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(mockFavoritesUseCase.isFavoriteCallCount >= 1)
        #expect(mockFavoritesUseCase.lastCheckedISBN13 == "9781234567890")
        #expect(sut.isFavorite == true)
    }

    @Test("loadBookDetail sets isFavorite to false when not favorited")
    func loadBookDetail_setsFavoriteFalse() async {
        // Given
        mockSearchBooksUseCase.stubbedBookDetail = BookDetail.stub()
        mockFavoritesUseCase.stubbedIsFavorite = false
        let sut = makeSUT()

        // When
        sut.loadBookDetail()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.isFavorite == false)
    }

    @Test("loadBookDetail sets errorMessage on failure")
    func loadBookDetail_setsErrorMessageOnFailure() async {
        // Given
        let error = NSError(
            domain: "TestError",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Book not found"]
        )
        mockSearchBooksUseCase.stubbedError = error
        let sut = makeSUT()

        // When
        sut.loadBookDetail()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.errorMessage != nil)
        #expect(sut.errorMessage?.contains("not found") == true)
        #expect(sut.isLoading == false)
        #expect(sut.bookDetail == nil)
    }

    @Test("loadBookDetail calls fetchBookDetail with correct ISBN")
    func loadBookDetail_callsFetchBookDetailWithCorrectISBN() async {
        // Given
        let isbn13 = "9789876543210"
        mockSearchBooksUseCase.stubbedBookDetail = BookDetail.stub(isbn13: isbn13)
        let sut = makeSUT(isbn13: isbn13)

        // When
        sut.loadBookDetail()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(mockSearchBooksUseCase.fetchBookDetailCallCount == 1)
        #expect(mockSearchBooksUseCase.lastISBN13 == isbn13)
    }

    // MARK: - toggleFavorite Tests

    @Test("toggleFavorite does nothing when bookDetail is nil")
    func toggleFavorite_doesNothingWhenBookDetailNil() async {
        // Given
        let sut = makeSUT()
        #expect(sut.bookDetail == nil)

        // When
        sut.toggleFavorite()

        // Then
        await waitForPublisher(timeout: 0.2)
        #expect(mockFavoritesUseCase.toggleFavoriteCallCount == 0)
    }

    @Test("toggleFavorite calls toggleFavorite on useCase with correct book")
    func toggleFavorite_callsUseCaseWithCorrectBook() async {
        // Given
        let detail = BookDetail.stub(
            isbn13: "9781234567890",
            title: "Test Book",
            authors: "Test Author",
            publisher: "Test Publisher"
        )
        mockSearchBooksUseCase.stubbedBookDetail = detail
        let sut = makeSUT()

        // Load book detail first
        sut.loadBookDetail()
        await waitForPublisher(timeout: 0.5)

        // When
        sut.toggleFavorite()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(mockFavoritesUseCase.toggleFavoriteCallCount == 1)
        #expect(mockFavoritesUseCase.lastToggledBook?.id == "9781234567890")
        #expect(mockFavoritesUseCase.lastToggledBook?.title == "Test Book")
        #expect(mockFavoritesUseCase.lastToggledBook?.authors == "Test Author")
        #expect(mockFavoritesUseCase.lastToggledBook?.publisher == "Test Publisher")
    }

    @Test("toggleFavorite updates isFavorite to true when toggled on")
    func toggleFavorite_updatesFavoriteToTrue() async {
        // Given
        mockSearchBooksUseCase.stubbedBookDetail = BookDetail.stub()
        mockFavoritesUseCase.stubbedToggleResult = true
        let sut = makeSUT()

        // Load book detail first
        sut.loadBookDetail()
        await waitForPublisher(timeout: 0.5)
        #expect(sut.isFavorite == false)

        // When
        sut.toggleFavorite()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.isFavorite == true)
    }

    @Test("toggleFavorite updates isFavorite to false when toggled off")
    func toggleFavorite_updatesFavoriteToFalse() async {
        // Given
        mockSearchBooksUseCase.stubbedBookDetail = BookDetail.stub()
        mockFavoritesUseCase.stubbedIsFavorite = true
        mockFavoritesUseCase.stubbedToggleResult = false
        let sut = makeSUT()

        // Load book detail first
        sut.loadBookDetail()
        await waitForPublisher(timeout: 0.5)
        #expect(sut.isFavorite == true)

        // When
        sut.toggleFavorite()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.isFavorite == false)
    }

    @Test("toggleFavorite creates FavoriteBook with correct properties")
    func toggleFavorite_createsFavoriteBookWithCorrectProperties() async {
        // Given
        let detail = BookDetail.stub(
            isbn13: "9781234567890",
            title: "Test Title",
            subtitle: "Test Subtitle",
            authors: "Test Authors",
            publisher: "Test Publisher",
            year: "2024",
            rating: "5",
            price: "$49.99",
            imageURL: "https://example.com/image.png"
        )
        mockSearchBooksUseCase.stubbedBookDetail = detail
        let sut = makeSUT()

        sut.loadBookDetail()
        await waitForPublisher(timeout: 0.5)

        // When
        sut.toggleFavorite()

        // Then
        await waitForPublisher(timeout: 0.5)
        let toggledBook = mockFavoritesUseCase.lastToggledBook
        #expect(toggledBook != nil)
        #expect(toggledBook?.id == "9781234567890")
        #expect(toggledBook?.title == "Test Title")
        #expect(toggledBook?.subtitle == "Test Subtitle")
        #expect(toggledBook?.authors == "Test Authors")
        #expect(toggledBook?.publisher == "Test Publisher")
        #expect(toggledBook?.year == "2024")
        #expect(toggledBook?.rating == "5")
        #expect(toggledBook?.price == "$49.99")
        #expect(toggledBook?.imageURL == "https://example.com/image.png")
    }

    // MARK: - Multiple Operations Tests

    @Test("loadBookDetail can be called multiple times")
    func loadBookDetail_canBeCalledMultipleTimes() async {
        // Given
        let detail1 = BookDetail.stub(title: "First Book")
        let detail2 = BookDetail.stub(title: "Second Book")
        let sut = makeSUT()

        // When - First load
        mockSearchBooksUseCase.stubbedBookDetail = detail1
        sut.loadBookDetail()
        await waitForPublisher(timeout: 0.5)

        // Then
        #expect(sut.bookDetail?.title == "First Book")
        #expect(mockSearchBooksUseCase.fetchBookDetailCallCount == 1)

        // When - Second load
        mockSearchBooksUseCase.stubbedBookDetail = detail2
        sut.loadBookDetail()
        await waitForPublisher(timeout: 0.5)

        // Then
        #expect(sut.bookDetail?.title == "Second Book")
        #expect(mockSearchBooksUseCase.fetchBookDetailCallCount == 2)
    }
}

// MARK: - Helper Functions

private func waitForPublisher(timeout: TimeInterval) async {
    try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
}
