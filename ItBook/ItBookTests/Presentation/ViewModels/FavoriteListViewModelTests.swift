//
//  FavoriteListViewModelTests.swift
//  ItBookTests
//
//  FavoriteListViewModel TDD tests
//  - loadFavorites tests
//  - removeFavorite tests
//  - Filter and sort tests
//  - Search functionality tests
//

import Testing
import Combine
import Foundation
@testable import ItBook

// MARK: - FavoriteListViewModel Tests

@Suite("FavoriteListViewModel Tests")
struct FavoriteListViewModelTests {

    // MARK: - Properties

    let mockFavoritesUseCase: MockManageFavoritesUseCase

    // MARK: - Init

    init() {
        mockFavoritesUseCase = MockManageFavoritesUseCase()
    }

    // MARK: - Factory

    private func makeSUT() -> FavoriteListViewModel {
        FavoriteListViewModel(favoritesUseCase: mockFavoritesUseCase)
    }

    // MARK: - Initialization Tests

    @Test("init sets initial state correctly")
    func init_setsInitialState() {
        // When
        let sut = makeSUT()

        // Then
        #expect(sut.favorites.isEmpty)
        #expect(sut.filteredFavorites.isEmpty)
        #expect(sut.isLoading == false)
        #expect(sut.searchQuery == "")
        #expect(sut.sortAscending == true)
        #expect(sut.maxPriceFilter == nil)
    }

    // MARK: - loadFavorites Tests

    @Test("loadFavorites sets isLoading to true")
    func loadFavorites_setsLoadingTrue() async {
        // Given
        mockFavoritesUseCase.stubbedFavorites = []
        mockFavoritesUseCase.delay = 0.5 // Add delay to keep loading state
        let sut = makeSUT()

        // When
        sut.loadFavorites()

        // Then - check loading state while delayed
        #expect(sut.isLoading == true)

        await waitForPublisher(timeout: 1.0)
    }

    @Test("loadFavorites updates favorites on success")
    func loadFavorites_updatesFavoritesOnSuccess() async {
        // Given
        let expectedFavorites = FavoriteBook.stubList(count: 3)
        mockFavoritesUseCase.stubbedFavorites = expectedFavorites
        let sut = makeSUT()

        // When
        sut.loadFavorites()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.favorites.count == 3)
        #expect(sut.isLoading == false)
    }

    @Test("loadFavorites updates filteredFavorites")
    func loadFavorites_updatesFilteredFavorites() async {
        // Given
        let expectedFavorites = FavoriteBook.stubList(count: 5)
        mockFavoritesUseCase.stubbedFavorites = expectedFavorites
        let sut = makeSUT()

        // When
        sut.loadFavorites()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.filteredFavorites.count == 5)
    }

    @Test("loadFavorites calls fetchAllFavorites on useCase")
    func loadFavorites_callsFetchAllFavorites() async {
        // Given
        mockFavoritesUseCase.stubbedFavorites = []
        let sut = makeSUT()

        // When
        sut.loadFavorites()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(mockFavoritesUseCase.fetchAllFavoritesCallCount == 1)
    }

    @Test("loadFavorites applies default sort (ascending)")
    func loadFavorites_appliesDefaultSort() async {
        // Given
        let favorites = [
            FavoriteBook.stub(isbn13: "9780000000001", title: "Zebra Book"),
            FavoriteBook.stub(isbn13: "9780000000002", title: "Apple Book"),
            FavoriteBook.stub(isbn13: "9780000000003", title: "Mango Book")
        ]
        mockFavoritesUseCase.stubbedFavorites = favorites
        let sut = makeSUT()

        // When
        sut.loadFavorites()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.filteredFavorites.first?.title == "Apple Book")
        #expect(sut.filteredFavorites.last?.title == "Zebra Book")
    }

    // MARK: - removeFavorite Tests

    @Test("removeFavorite calls removeFavorite on useCase with correct ISBN")
    func removeFavorite_callsUseCaseWithCorrectISBN() async {
        // Given
        let book = FavoriteBook.stub(isbn13: "9781234567890")
        mockFavoritesUseCase.stubbedFavorites = [book]
        let sut = makeSUT()

        // Load favorites first
        sut.loadFavorites()
        await waitForPublisher(timeout: 0.5)

        // When
        sut.removeFavorite(book)

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(mockFavoritesUseCase.removeFavoriteCallCount == 1)
        #expect(mockFavoritesUseCase.lastRemovedISBN13 == "9781234567890")
    }

    @Test("removeFavorite reloads favorites after removal")
    func removeFavorite_reloadsFavoritesAfterRemoval() async {
        // Given
        let book = FavoriteBook.stub(isbn13: "9781234567890")
        mockFavoritesUseCase.stubbedFavorites = [book]
        let sut = makeSUT()

        // Load favorites first
        sut.loadFavorites()
        await waitForPublisher(timeout: 0.5)

        let initialFetchCount = mockFavoritesUseCase.fetchAllFavoritesCallCount

        // When
        sut.removeFavorite(book)

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(mockFavoritesUseCase.fetchAllFavoritesCallCount > initialFetchCount)
    }

    // MARK: - toggleSort Tests

    @Test("toggleSort changes sortAscending from true to false")
    func toggleSort_changesToDescending() {
        // Given
        let sut = makeSUT()
        #expect(sut.sortAscending == true)

        // When
        sut.toggleSort()

        // Then
        #expect(sut.sortAscending == false)
    }

    @Test("toggleSort changes sortAscending from false to true")
    func toggleSort_changesToAscending() {
        // Given
        let sut = makeSUT()
        sut.toggleSort() // First toggle to false
        #expect(sut.sortAscending == false)

        // When
        sut.toggleSort()

        // Then
        #expect(sut.sortAscending == true)
    }

    @Test("toggleSort triggers filter and sort reapplication")
    func toggleSort_reappliesFiltersAndSort() async {
        // Given
        let favorites = [
            FavoriteBook.stub(isbn13: "9780000000001", title: "Zebra Book"),
            FavoriteBook.stub(isbn13: "9780000000002", title: "Apple Book")
        ]
        mockFavoritesUseCase.stubbedFavorites = favorites
        let sut = makeSUT()

        sut.loadFavorites()
        await waitForPublisher(timeout: 0.5)

        // Initially ascending
        #expect(sut.filteredFavorites.first?.title == "Apple Book")

        // When
        sut.toggleSort()

        // Then - need to wait for debounce (200ms) + processing
        await waitForPublisher(timeout: 0.5)
        #expect(sut.filteredFavorites.first?.title == "Zebra Book")
    }

    // MARK: - setPriceFilter Tests

    @Test("setPriceFilter updates maxPriceFilter")
    func setPriceFilter_updatesMaxPriceFilter() {
        // Given
        let sut = makeSUT()
        #expect(sut.maxPriceFilter == nil)

        // When
        sut.setPriceFilter(50.0)

        // Then
        #expect(sut.maxPriceFilter == 50.0)
    }

    @Test("setPriceFilter with nil clears the filter")
    func setPriceFilter_withNilClearsFilter() {
        // Given
        let sut = makeSUT()
        sut.setPriceFilter(50.0)
        #expect(sut.maxPriceFilter == 50.0)

        // When
        sut.setPriceFilter(nil)

        // Then
        #expect(sut.maxPriceFilter == nil)
    }

    @Test("setPriceFilter filters favorites by price")
    func setPriceFilter_filtersFavoritesByPrice() async {
        // Given
        let favorites = [
            FavoriteBook.stub(isbn13: "9780000000001", title: "Cheap Book", price: "$19.99"),
            FavoriteBook.stub(isbn13: "9780000000002", title: "Mid Book", price: "$39.99"),
            FavoriteBook.stub(isbn13: "9780000000003", title: "Expensive Book", price: "$99.99")
        ]
        mockFavoritesUseCase.stubbedFavorites = favorites
        let sut = makeSUT()

        sut.loadFavorites()
        await waitForPublisher(timeout: 0.5)

        // When
        sut.setPriceFilter(40.0)

        // Then - wait for debounce
        await waitForPublisher(timeout: 0.5)
        #expect(sut.filteredFavorites.count == 2)
        #expect(sut.filteredFavorites.contains { $0.title == "Cheap Book" })
        #expect(sut.filteredFavorites.contains { $0.title == "Mid Book" })
        #expect(!sut.filteredFavorites.contains { $0.title == "Expensive Book" })
    }

    // MARK: - clearFilters Tests

    @Test("clearFilters resets all filters to default")
    func clearFilters_resetsAllFilters() {
        // Given
        let sut = makeSUT()
        sut.searchQuery = "test"
        sut.setPriceFilter(50.0)
        sut.toggleSort() // sortAscending = false

        // When
        sut.clearFilters()

        // Then
        #expect(sut.searchQuery == "")
        #expect(sut.maxPriceFilter == nil)
        #expect(sut.sortAscending == true)
    }

    @Test("clearFilters shows all favorites")
    func clearFilters_showsAllFavorites() async {
        // Given
        let favorites = FavoriteBook.stubList(count: 5)
        mockFavoritesUseCase.stubbedFavorites = favorites
        let sut = makeSUT()

        sut.loadFavorites()
        await waitForPublisher(timeout: 0.5)

        // Apply filters
        sut.searchQuery = "nonexistent"
        await waitForPublisher(timeout: 0.5)
        #expect(sut.filteredFavorites.count < 5)

        // When
        sut.clearFilters()

        // Then - wait for debounce
        await waitForPublisher(timeout: 0.5)
        #expect(sut.filteredFavorites.count == 5)
    }

    // MARK: - searchQuery Tests

    @Test("searchQuery filters by title")
    func searchQuery_filtersByTitle() async {
        // Given
        let favorites = [
            FavoriteBook.stub(isbn13: "9780000000001", title: "Swift Programming", authors: "Author A"),
            FavoriteBook.stub(isbn13: "9780000000002", title: "iOS Development", authors: "Author B"),
            FavoriteBook.stub(isbn13: "9780000000003", title: "Python Basics", authors: "Author C")
        ]
        mockFavoritesUseCase.stubbedFavorites = favorites
        let sut = makeSUT()

        sut.loadFavorites()
        await waitForPublisher(timeout: 0.5)

        // When
        sut.searchQuery = "Swift"

        // Then - wait for debounce (200ms)
        await waitForPublisher(timeout: 0.5)
        #expect(sut.filteredFavorites.count == 1)
        #expect(sut.filteredFavorites.first?.title == "Swift Programming")
    }

    @Test("searchQuery filters by author")
    func searchQuery_filtersByAuthor() async {
        // Given
        let favorites = [
            FavoriteBook.stub(isbn13: "9780000000001", title: "Book A", authors: "John Smith"),
            FavoriteBook.stub(isbn13: "9780000000002", title: "Book B", authors: "Jane Doe"),
            FavoriteBook.stub(isbn13: "9780000000003", title: "Book C", authors: "John Doe")
        ]
        mockFavoritesUseCase.stubbedFavorites = favorites
        let sut = makeSUT()

        sut.loadFavorites()
        await waitForPublisher(timeout: 0.5)

        // When
        sut.searchQuery = "John"

        // Then - wait for debounce
        await waitForPublisher(timeout: 0.5)
        #expect(sut.filteredFavorites.count == 2)
    }

    @Test("searchQuery is case insensitive")
    func searchQuery_isCaseInsensitive() async {
        // Given
        let favorites = [
            FavoriteBook.stub(isbn13: "9780000000001", title: "SWIFT Programming", authors: "Author")
        ]
        mockFavoritesUseCase.stubbedFavorites = favorites
        let sut = makeSUT()

        sut.loadFavorites()
        await waitForPublisher(timeout: 0.5)

        // When
        sut.searchQuery = "swift"

        // Then - wait for debounce
        await waitForPublisher(timeout: 0.5)
        #expect(sut.filteredFavorites.count == 1)
    }

    @Test("empty searchQuery shows all favorites")
    func emptySearchQuery_showsAllFavorites() async {
        // Given
        let favorites = FavoriteBook.stubList(count: 3)
        mockFavoritesUseCase.stubbedFavorites = favorites
        let sut = makeSUT()

        sut.loadFavorites()
        await waitForPublisher(timeout: 0.5)

        // Apply search then clear
        sut.searchQuery = "test"
        await waitForPublisher(timeout: 0.5)

        // When
        sut.searchQuery = ""

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.filteredFavorites.count == 3)
    }

    // MARK: - Combined Filters Tests

    @Test("search and price filter work together")
    func searchAndPriceFilter_workTogether() async {
        // Given
        let favorites = [
            FavoriteBook.stub(isbn13: "9780000000001", title: "Swift Book", price: "$19.99"),
            FavoriteBook.stub(isbn13: "9780000000002", title: "Swift Advanced", price: "$59.99"),
            FavoriteBook.stub(isbn13: "9780000000003", title: "iOS Book", price: "$29.99")
        ]
        mockFavoritesUseCase.stubbedFavorites = favorites
        let sut = makeSUT()

        sut.loadFavorites()
        await waitForPublisher(timeout: 0.5)

        // When - apply both filters
        sut.searchQuery = "Swift"
        sut.setPriceFilter(30.0)

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.filteredFavorites.count == 1)
        #expect(sut.filteredFavorites.first?.title == "Swift Book")
    }

    @Test("search, price, and sort work together")
    func searchPriceAndSort_workTogether() async {
        // Given
        let favorites = [
            FavoriteBook.stub(isbn13: "9780000000001", title: "Zebra Swift", price: "$19.99"),
            FavoriteBook.stub(isbn13: "9780000000002", title: "Apple Swift", price: "$29.99"),
            FavoriteBook.stub(isbn13: "9780000000003", title: "Mango Swift", price: "$99.99")
        ]
        mockFavoritesUseCase.stubbedFavorites = favorites
        let sut = makeSUT()

        sut.loadFavorites()
        await waitForPublisher(timeout: 0.5)

        // When
        sut.searchQuery = "Swift"
        sut.setPriceFilter(50.0)
        sut.toggleSort() // descending

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.filteredFavorites.count == 2)
        #expect(sut.filteredFavorites.first?.title == "Zebra Swift")
        #expect(sut.filteredFavorites.last?.title == "Apple Swift")
    }

    // MARK: - Edge Cases

    @Test("loadFavorites with empty list")
    func loadFavorites_withEmptyList() async {
        // Given
        mockFavoritesUseCase.stubbedFavorites = []
        let sut = makeSUT()

        // When
        sut.loadFavorites()

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.favorites.isEmpty)
        #expect(sut.filteredFavorites.isEmpty)
        #expect(sut.isLoading == false)
    }

    @Test("filter with no matching results")
    func filter_withNoMatchingResults() async {
        // Given
        let favorites = FavoriteBook.stubList(count: 3)
        mockFavoritesUseCase.stubbedFavorites = favorites
        let sut = makeSUT()

        sut.loadFavorites()
        await waitForPublisher(timeout: 0.5)

        // When
        sut.searchQuery = "nonexistent_search_term"

        // Then
        await waitForPublisher(timeout: 0.5)
        #expect(sut.filteredFavorites.isEmpty)
        // Original favorites should still be there
        #expect(sut.favorites.count == 3)
    }

    @Test("multiple rapid filter changes apply final state")
    func multipleRapidFilterChanges_applyFinalState() async {
        // Given
        let favorites = [
            FavoriteBook.stub(isbn13: "9780000000001", title: "AAA Book"),
            FavoriteBook.stub(isbn13: "9780000000002", title: "BBB Book"),
            FavoriteBook.stub(isbn13: "9780000000003", title: "CCC Book")
        ]
        mockFavoritesUseCase.stubbedFavorites = favorites
        let sut = makeSUT()

        sut.loadFavorites()
        await waitForPublisher(timeout: 0.5)

        // When - rapid changes
        sut.searchQuery = "A"
        sut.searchQuery = "B"
        sut.searchQuery = "C"

        // Then - should show only "CCC Book" (debounce should use last value)
        await waitForPublisher(timeout: 0.5)
        #expect(sut.filteredFavorites.count == 1)
        #expect(sut.filteredFavorites.first?.title == "CCC Book")
    }
}

// MARK: - Helper Functions

private func waitForPublisher(timeout: TimeInterval) async {
    try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
}
