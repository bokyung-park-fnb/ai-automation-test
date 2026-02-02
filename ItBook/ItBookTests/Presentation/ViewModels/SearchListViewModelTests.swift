//
//  SearchListViewModelTests.swift
//  ItBookTests
//
//  SearchListViewModel TDD tests
//  - loadNewBooks tests
//  - searchBooks tests
//  - Pagination tests
//  - Favorite toggle tests
//  - Error handling tests
//

import Testing
import Combine
import Foundation
@testable import ItBook

// MARK: - SearchListViewModel Tests

@Suite("SearchListViewModel Tests")
struct SearchListViewModelTests {

    // MARK: - Properties

    let mockSearchBooksUseCase: MockSearchBooksUseCase
    let mockFavoritesUseCase: MockManageFavoritesUseCase

    // MARK: - Init

    init() {
        mockSearchBooksUseCase = MockSearchBooksUseCase()
        mockFavoritesUseCase = MockManageFavoritesUseCase()
    }

    // MARK: - Factory

    private func makeSUT() -> SearchListViewModel {
        SearchListViewModel(
            searchBooksUseCase: mockSearchBooksUseCase,
            favoritesUseCase: mockFavoritesUseCase
        )
    }

    // MARK: - Initialization Tests

    @Test("init sets initial state correctly")
    func init_setsInitialState() {
        // When
        let sut = makeSUT()

        // Then
        #expect(sut.books.isEmpty)
        #expect(sut.isLoading == false)
        #expect(sut.isLoadingMore == false)
        #expect(sut.errorMessage == nil)
        #expect(sut.searchQuery == "")
        #expect(sut.favoriteChangedBookId == nil)
    }

    // MARK: - loadNewBooks Tests

    @Test("loadNewBooks sets isLoading to true")
    func loadNewBooks_setsLoadingTrue() async {
        // Given
        mockSearchBooksUseCase.stubbedNewBooks = []
        mockSearchBooksUseCase.delay = 0.5 // Add delay to keep loading state
        let sut = makeSUT()

        // Wait for debounce-triggered call to complete first
        await waitForPublisher(timeout: 0.5)

        // When - call manually
        sut.loadNewBooks()

        // Then - check loading state while delayed
        #expect(sut.isLoading == true)

        await waitForPublisher(timeout: 1.0)
    }

    @Test("loadNewBooks clears error message")
    func loadNewBooks_clearsErrorMessage() async {
        // Given
        let sut = makeSUT()

        // Simulate previous error
        mockSearchBooksUseCase.stubbedError = NSError(domain: "Test", code: -1)
        sut.loadNewBooks()
        await waitForPublisher(timeout: 0.5)

        // Reset for successful load
        mockSearchBooksUseCase.stubbedError = nil
        mockSearchBooksUseCase.stubbedNewBooks = []

        // When
        sut.loadNewBooks()

        // Then
        #expect(sut.errorMessage == nil)

        await waitForPublisher(timeout: 0.5)
    }

    @Test("loadNewBooks updates books on success")
    func loadNewBooks_updatesBooksOnSuccess() async {
        // Given
        let expectedBooks = Book.stubList(count: 5)
        mockSearchBooksUseCase.stubbedNewBooks = expectedBooks
        let sut = makeSUT()

        // When
        sut.loadNewBooks()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.books.count == 5)
        #expect(sut.isLoading == false)
    }

    @Test("loadNewBooks calls fetchNewBooks on useCase")
    func loadNewBooks_callsFetchNewBooks() async {
        // Given
        mockSearchBooksUseCase.stubbedNewBooks = []
        let sut = makeSUT()

        // Wait for debounce-triggered call (init triggers empty query -> loadNewBooks)
        await waitForPublisher(timeout: 0.5)
        let initialCallCount = mockSearchBooksUseCase.fetchNewBooksCallCount

        // When
        sut.loadNewBooks()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(mockSearchBooksUseCase.fetchNewBooksCallCount == initialCallCount + 1)
    }

    @Test("loadNewBooks sets errorMessage on failure")
    func loadNewBooks_setsErrorMessageOnFailure() async {
        // Given
        let error = NSError(
            domain: "TestError",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Server error"]
        )
        mockSearchBooksUseCase.stubbedError = error
        let sut = makeSUT()

        // When
        sut.loadNewBooks()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.errorMessage != nil)
        #expect(sut.errorMessage?.contains("Server error") == true)
        #expect(sut.isLoading == false)
    }

    @Test("loadNewBooks does not load when already loading")
    func loadNewBooks_doesNotLoadWhenAlreadyLoading() async {
        // Given
        mockSearchBooksUseCase.stubbedNewBooks = []
        mockSearchBooksUseCase.delay = 1.0 // Add delay to keep loading state
        let sut = makeSUT()

        // When - call twice rapidly
        sut.loadNewBooks()
        sut.loadNewBooks()

        // Then - should only call once
        #expect(mockSearchBooksUseCase.fetchNewBooksCallCount == 1)

        await waitForPublisher(timeout: 1.5)
    }

    // MARK: - searchBooks Tests

    @Test("searchBooks sets isLoading to true")
    func searchBooks_setsLoadingTrue() async {
        // Given
        mockSearchBooksUseCase.stubbedSearchResult = (books: [], total: 0)
        mockSearchBooksUseCase.delay = 0.5 // Add delay to keep loading state
        let sut = makeSUT()

        // Wait for initial debounce trigger
        await waitForPublisher(timeout: 0.5)

        sut.searchQuery = "Swift"

        // When
        sut.searchBooks()

        // Then
        #expect(sut.isLoading == true)

        await waitForPublisher(timeout: 1.0)
    }

    @Test("searchBooks updates books on success")
    func searchBooks_updatesBooksOnSuccess() async {
        // Given
        let expectedBooks = Book.stubList(count: 10)
        mockSearchBooksUseCase.stubbedSearchResult = (books: expectedBooks, total: 100)
        let sut = makeSUT()
        sut.searchQuery = "Swift"

        // When
        sut.searchBooks()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.books.count == 10)
        #expect(sut.isLoading == false)
    }

    @Test("searchBooks calls searchBooks on useCase with correct query")
    func searchBooks_callsUseCaseWithCorrectQuery() async {
        // Given
        mockSearchBooksUseCase.stubbedSearchResult = (books: [], total: 0)
        let sut = makeSUT()

        // Wait for initial debounce trigger
        await waitForPublisher(timeout: 0.5)

        sut.searchQuery = "iOS Programming"

        // When - wait for debounce to trigger search
        await waitForPublisher(timeout: 0.5)

        // Then
        #expect(mockSearchBooksUseCase.lastSearchQuery == "iOS Programming")
        #expect(mockSearchBooksUseCase.lastSearchPage == 1)
    }

    @Test("searchBooks does not search when query is empty")
    func searchBooks_doesNotSearchWhenQueryEmpty() async {
        // Given
        let sut = makeSUT()
        sut.searchQuery = ""

        // When
        sut.searchBooks()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(mockSearchBooksUseCase.searchBooksCallCount == 0)
    }

    @Test("searchBooks does not search when already loading")
    func searchBooks_doesNotSearchWhenAlreadyLoading() async {
        // Given
        mockSearchBooksUseCase.stubbedSearchResult = (books: [], total: 0)
        mockSearchBooksUseCase.delay = 1.0
        let sut = makeSUT()
        sut.searchQuery = "Swift"

        // When - call twice
        sut.searchBooks()
        sut.searchBooks()

        // Then
        #expect(mockSearchBooksUseCase.searchBooksCallCount == 1)

        await waitForPublisher(timeout: 1.5)
    }

    @Test("searchBooks sets errorMessage on failure")
    func searchBooks_setsErrorMessageOnFailure() async {
        // Given
        let error = NSError(
            domain: "TestError",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Not found"]
        )
        mockSearchBooksUseCase.stubbedError = error
        let sut = makeSUT()
        sut.searchQuery = "Swift"

        // When
        sut.searchBooks()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.errorMessage != nil)
        #expect(sut.errorMessage?.contains("Not found") == true)
    }

    @Test("searchBooks resets page to 1")
    func searchBooks_resetsPageToOne() async {
        // Given
        mockSearchBooksUseCase.stubbedSearchResult = (books: Book.stubList(count: 10), total: 100)
        let sut = makeSUT()
        sut.searchQuery = "Swift"

        // Simulate being on page 2
        sut.searchBooks()
        await waitForPublisher(timeout: 0.5)

        // When - new search
        sut.searchQuery = "iOS"
        sut.searchBooks()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(mockSearchBooksUseCase.lastSearchPage == 1)
    }

    // MARK: - loadMoreIfNeeded Tests

    @Test("loadMoreIfNeeded loads more when near end of list")
    func loadMoreIfNeeded_loadsMoreWhenNearEnd() async {
        // Given
        let initialBooks = Book.stubList(count: 10)
        mockSearchBooksUseCase.stubbedSearchResult = (books: initialBooks, total: 100)
        let sut = makeSUT()

        // Wait for initial debounce trigger
        await waitForPublisher(timeout: 0.5)

        sut.searchQuery = "Swift"

        // Wait for debounce to trigger search
        await waitForPublisher(timeout: 0.5)

        let lastBook = sut.books[sut.books.count - 1]
        let callCountAfterInitialSearch = mockSearchBooksUseCase.searchBooksCallCount

        // Prepare more books
        mockSearchBooksUseCase.stubbedSearchResult = (books: Book.stubList(count: 10), total: 100)

        // When
        sut.loadMoreIfNeeded(currentItem: lastBook)

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(mockSearchBooksUseCase.searchBooksCallCount == callCountAfterInitialSearch + 1)
        #expect(mockSearchBooksUseCase.lastSearchPage == 2)
    }

    @Test("loadMoreIfNeeded sets isLoadingMore to true")
    func loadMoreIfNeeded_setsLoadingMoreTrue() async {
        // Given
        let initialBooks = Book.stubList(count: 10)
        mockSearchBooksUseCase.stubbedSearchResult = (books: initialBooks, total: 100)
        let sut = makeSUT()
        sut.searchQuery = "Swift"

        sut.searchBooks()
        await waitForPublisher(timeout: 0.5)

        let lastBook = sut.books[sut.books.count - 1]
        mockSearchBooksUseCase.delay = 0.5

        // When
        sut.loadMoreIfNeeded(currentItem: lastBook)

        // Then
        #expect(sut.isLoadingMore == true)

        await waitForPublisher(timeout: 1.0)
    }

    @Test("loadMoreIfNeeded appends new books")
    func loadMoreIfNeeded_appendsNewBooks() async {
        // Given
        let initialBooks = Book.stubList(count: 10)
        mockSearchBooksUseCase.stubbedSearchResult = (books: initialBooks, total: 100)
        let sut = makeSUT()
        sut.searchQuery = "Swift"

        sut.searchBooks()
        await waitForPublisher(timeout: 0.5)
        #expect(sut.books.count == 10)

        let lastBook = sut.books[sut.books.count - 1]

        // New books for page 2
        let moreBooks = (10..<20).map { Book.stub(isbn13: "978000000000\($0)") }
        mockSearchBooksUseCase.stubbedSearchResult = (books: moreBooks, total: 100)

        // When
        sut.loadMoreIfNeeded(currentItem: lastBook)

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.books.count == 20)
    }

    @Test("loadMoreIfNeeded does not load when not near end")
    func loadMoreIfNeeded_doesNotLoadWhenNotNearEnd() async {
        // Given
        let initialBooks = Book.stubList(count: 10)
        mockSearchBooksUseCase.stubbedSearchResult = (books: initialBooks, total: 100)
        let sut = makeSUT()
        sut.searchQuery = "Swift"

        sut.searchBooks()
        await waitForPublisher(timeout: 0.5)

        let firstBook = sut.books[0]
        let initialCallCount = mockSearchBooksUseCase.searchBooksCallCount

        // When
        sut.loadMoreIfNeeded(currentItem: firstBook)

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(mockSearchBooksUseCase.searchBooksCallCount == initialCallCount)
    }

    @Test("loadMoreIfNeeded does not load when no more pages")
    func loadMoreIfNeeded_doesNotLoadWhenNoMorePages() async {
        // Given
        let allBooks = Book.stubList(count: 10)
        mockSearchBooksUseCase.stubbedSearchResult = (books: allBooks, total: 10) // total = count
        let sut = makeSUT()
        sut.searchQuery = "Swift"

        sut.searchBooks()
        await waitForPublisher(timeout: 0.5)

        let lastBook = sut.books[sut.books.count - 1]
        let initialCallCount = mockSearchBooksUseCase.searchBooksCallCount

        // When
        sut.loadMoreIfNeeded(currentItem: lastBook)

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(mockSearchBooksUseCase.searchBooksCallCount == initialCallCount)
    }

    @Test("loadMoreIfNeeded does not load when already loading more")
    func loadMoreIfNeeded_doesNotLoadWhenAlreadyLoadingMore() async {
        // Given
        let initialBooks = Book.stubList(count: 10)
        mockSearchBooksUseCase.stubbedSearchResult = (books: initialBooks, total: 100)
        let sut = makeSUT()

        // Wait for initial debounce trigger
        await waitForPublisher(timeout: 0.5)

        sut.searchQuery = "Swift"

        // Wait for debounce to trigger search
        await waitForPublisher(timeout: 0.5)

        let lastBook = sut.books[sut.books.count - 1]
        let callCountAfterInitialSearch = mockSearchBooksUseCase.searchBooksCallCount
        mockSearchBooksUseCase.delay = 1.0

        // When - call twice
        sut.loadMoreIfNeeded(currentItem: lastBook)
        sut.loadMoreIfNeeded(currentItem: lastBook)

        // Then - should only call once (one load more)
        #expect(mockSearchBooksUseCase.searchBooksCallCount == callCountAfterInitialSearch + 1)

        await waitForPublisher(timeout: 1.5)
    }

    @Test("loadMoreIfNeeded does not load when searchQuery is empty")
    func loadMoreIfNeeded_doesNotLoadWhenQueryEmpty() async {
        // Given
        let initialBooks = Book.stubList(count: 10)
        mockSearchBooksUseCase.stubbedNewBooks = initialBooks
        let sut = makeSUT()

        // Load new books (no search query)
        sut.loadNewBooks()
        await waitForPublisher(timeout: 0.5)

        let lastBook = sut.books[sut.books.count - 1]
        let initialCallCount = mockSearchBooksUseCase.searchBooksCallCount

        // When
        sut.loadMoreIfNeeded(currentItem: lastBook)

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(mockSearchBooksUseCase.searchBooksCallCount == initialCallCount)
    }

    @Test("loadMoreIfNeeded decrements page on failure")
    func loadMoreIfNeeded_decrementsPageOnFailure() async {
        // Given
        let initialBooks = Book.stubList(count: 10)
        mockSearchBooksUseCase.stubbedSearchResult = (books: initialBooks, total: 100)
        let sut = makeSUT()
        sut.searchQuery = "Swift"

        sut.searchBooks()
        await waitForPublisher(timeout: 0.5)

        let lastBook = sut.books[sut.books.count - 1]

        // Set error for load more
        mockSearchBooksUseCase.stubbedError = NSError(domain: "Test", code: -1)

        // When
        sut.loadMoreIfNeeded(currentItem: lastBook)
        await waitForPublisher(timeout: 0.5)

        // Reset error and try again
        mockSearchBooksUseCase.stubbedError = nil
        mockSearchBooksUseCase.stubbedSearchResult = (books: [], total: 100)

        sut.loadMoreIfNeeded(currentItem: lastBook)
        await waitForPublisher(timeout: 0.5)

        // Then - page should still be 2 (decremented from 2 to 1, then incremented back to 2)
        #expect(mockSearchBooksUseCase.lastSearchPage == 2)
    }

    // MARK: - isFavorite Tests

    @Test("isFavorite returns publisher with correct value")
    func isFavorite_returnsPublisherWithCorrectValue() async throws {
        // Given
        mockFavoritesUseCase.stubbedIsFavorite = true
        let sut = makeSUT()

        // When
        let result = try await awaitPublisher(sut.isFavorite(isbn13: "9781234567890"))

        // Then
        #expect(result == true)
        #expect(mockFavoritesUseCase.isFavoriteCallCount == 1)
        #expect(mockFavoritesUseCase.lastCheckedISBN13 == "9781234567890")
    }

    @Test("isFavorite returns false on error")
    func isFavorite_returnsFalseOnError() async throws {
        // Given
        mockFavoritesUseCase.stubbedError = NSError(domain: "Test", code: -1)
        let sut = makeSUT()

        // When
        let result = try await awaitPublisher(sut.isFavorite(isbn13: "9781234567890"))

        // Then
        #expect(result == false)
    }

    // MARK: - toggleFavorite Tests

    @Test("toggleFavorite calls toggleFavorite on useCase")
    func toggleFavorite_callsUseCaseToggleFavorite() async {
        // Given
        let book = Book.stub(isbn13: "9781234567890")
        let detail = BookDetail.stub(authors: "Test Author", publisher: "Test Publisher")
        let sut = makeSUT()

        // When
        sut.toggleFavorite(book: book, detail: detail)

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(mockFavoritesUseCase.toggleFavoriteCallCount == 1)
    }

    @Test("toggleFavorite creates FavoriteBook with correct properties")
    func toggleFavorite_createsFavoriteBookWithCorrectProperties() async {
        // Given
        let book = Book.stub(
            isbn13: "9781234567890",
            title: "Test Title",
            subtitle: "Test Subtitle",
            price: "$29.99",
            imageURL: "https://example.com/image.png"
        )
        let detail = BookDetail.stub(
            authors: "Test Author",
            publisher: "Test Publisher",
            year: "2024",
            rating: "5"
        )
        let sut = makeSUT()

        // When
        sut.toggleFavorite(book: book, detail: detail)

        // Then
        await waitForPublisher(timeout: 0.5)
        let toggledBook = mockFavoritesUseCase.lastToggledBook
        #expect(toggledBook?.id == "9781234567890")
        #expect(toggledBook?.title == "Test Title")
        #expect(toggledBook?.subtitle == "Test Subtitle")
        #expect(toggledBook?.authors == "Test Author")
        #expect(toggledBook?.publisher == "Test Publisher")
        #expect(toggledBook?.price == "$29.99")
        #expect(toggledBook?.imageURL == "https://example.com/image.png")
        #expect(toggledBook?.year == "2024")
        #expect(toggledBook?.rating == "5")
    }

    @Test("toggleFavorite handles nil detail")
    func toggleFavorite_handlesNilDetail() async {
        // Given
        let book = Book.stub(isbn13: "9781234567890")
        let sut = makeSUT()

        // When
        sut.toggleFavorite(book: book, detail: nil)

        // Then
        await waitForPublisher(timeout: 0.5)
        let toggledBook = mockFavoritesUseCase.lastToggledBook
        #expect(toggledBook?.authors == "")
        #expect(toggledBook?.publisher == "")
        #expect(toggledBook?.year == nil)
        #expect(toggledBook?.rating == nil)
    }

    @Test("toggleFavorite updates favoriteChangedBookId")
    func toggleFavorite_updatesFavoriteChangedBookId() async {
        // Given
        let book = Book.stub(isbn13: "9781234567890")
        let sut = makeSUT()

        // When
        sut.toggleFavorite(book: book, detail: nil)

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.favoriteChangedBookId == "9781234567890")
    }

    // MARK: - Search Debounce Tests

    @Test("searchQuery change triggers search after debounce")
    func searchQueryChange_triggersSearchAfterDebounce() async {
        // Given
        mockSearchBooksUseCase.stubbedSearchResult = (books: [], total: 0)
        mockSearchBooksUseCase.stubbedNewBooks = []
        let sut = makeSUT()

        // When
        sut.searchQuery = "Swift"

        // Then - should not have searched immediately (debounce is 300ms)
        await waitForPublisher(timeout: 0.1)
        let countBeforeDebounce = mockSearchBooksUseCase.searchBooksCallCount

        // Wait for debounce to complete
        await waitForPublisher(timeout: 0.5)
        #expect(mockSearchBooksUseCase.searchBooksCallCount > countBeforeDebounce)
    }

    @Test("empty searchQuery loads new books")
    func emptySearchQuery_loadsNewBooks() async {
        // Given
        mockSearchBooksUseCase.stubbedNewBooks = Book.stubList(count: 5)
        mockSearchBooksUseCase.stubbedSearchResult = (books: [], total: 0)
        let sut = makeSUT()

        // Set query first
        sut.searchQuery = "Swift"
        await waitForPublisher(timeout: 0.5)

        let initialNewBooksCallCount = mockSearchBooksUseCase.fetchNewBooksCallCount

        // When - clear query
        sut.searchQuery = ""

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(mockSearchBooksUseCase.fetchNewBooksCallCount > initialNewBooksCallCount)
    }

    // MARK: - Edge Cases

    @Test("loadNewBooks with empty result")
    func loadNewBooks_withEmptyResult() async {
        // Given
        mockSearchBooksUseCase.stubbedNewBooks = []
        let sut = makeSUT()

        // When
        sut.loadNewBooks()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.books.isEmpty)
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
    }

    @Test("searchBooks with empty result")
    func searchBooks_withEmptyResult() async {
        // Given
        mockSearchBooksUseCase.stubbedSearchResult = (books: [], total: 0)
        let sut = makeSUT()
        sut.searchQuery = "NonexistentBook12345"

        // When
        sut.searchBooks()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.books.isEmpty)
        #expect(sut.isLoading == false)
    }
}

// MARK: - Helper Functions

private func waitForPublisher(timeout: TimeInterval) async {
    try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
}

private func awaitPublisher<T>(_ publisher: AnyPublisher<T, Never>) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
        var cancellable: AnyCancellable?
        cancellable = publisher
            .first()
            .sink(
                receiveCompletion: { _ in
                    cancellable?.cancel()
                },
                receiveValue: { value in
                    continuation.resume(returning: value)
                }
            )
    }
}
