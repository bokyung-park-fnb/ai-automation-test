import UIKit
import Combine
import SwiftUI

// MARK: - SearchListViewController

final class SearchListViewController: UIViewController {

    // MARK: - Properties

    private let viewModel = SearchListViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.placeholder = "도서 검색"
        return controller
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        return collectionView
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "검색 결과가 없습니다"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.isHidden = true
        return label
    }()

    private var dataSource: UICollectionViewDiffableDataSource<CollectionSection, Book>!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDataSource()
        bindViewModel()
        viewModel.loadNewBooks()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "IT Book"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        view.addSubview(collectionView)
        view.addSubview(loadingIndicator)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(140)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(140)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)

        return UICollectionViewCompositionalLayout(section: section)
    }

    private func setupDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Book> { [weak self] cell, _, book in
            guard let self else { return }

            cell.contentConfiguration = UIHostingConfiguration {
                BookCardView(
                    book: book,
                    isFavorite: self.checkFavoriteStatus(isbn13: book.id),
                    onFavoriteTap: { [weak self] in
                        self?.viewModel.toggleFavorite(book: book, detail: nil)
                    }
                )
            }
            .margins(.all, 0)
        }

        dataSource = UICollectionViewDiffableDataSource<CollectionSection, Book>(
            collectionView: collectionView
        ) { collectionView, indexPath, book in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: book
            )
        }
    }

    private func bindViewModel() {
        viewModel.$books
            .receive(on: DispatchQueue.main)
            .sink { [weak self] books in
                self?.updateSnapshot(with: books)
                self?.emptyLabel.isHidden = !books.isEmpty
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showError(message)
            }
            .store(in: &cancellables)

        viewModel.$favoriteChangedBookId
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bookId in
                self?.reconfigureItem(bookId: bookId)
            }
            .store(in: &cancellables)
    }

    private func updateSnapshot(with books: [Book]) {
        var snapshot = NSDiffableDataSourceSnapshot<CollectionSection, Book>()
        snapshot.appendSections([CollectionSection.main])
        snapshot.appendItems(books)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func reconfigureItem(bookId: String) {
        guard let book = viewModel.books.first(where: { $0.id == bookId }) else { return }

        var snapshot = dataSource.snapshot()
        snapshot.reconfigureItems([book])
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func checkFavoriteStatus(isbn13: String) -> Bool {
        let storage = FavoriteStorage()
        return storage.exists(isbn13: isbn13)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UISearchResultsUpdating

extension SearchListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.searchQuery = searchController.searchBar.text ?? ""
    }
}

// MARK: - UICollectionViewDelegate

extension SearchListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let book = dataSource.itemIdentifier(for: indexPath) else { return }

        let detailVC = BookDetailViewController(isbn13: book.id)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let book = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.loadMoreIfNeeded(currentItem: book)
    }
}
