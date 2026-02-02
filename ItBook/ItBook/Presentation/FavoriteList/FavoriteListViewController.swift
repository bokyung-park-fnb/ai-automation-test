import UIKit
import Combine
import SwiftUI

// MARK: - FavoriteListViewController

final class FavoriteListViewController: UIViewController {

    // MARK: - Properties

    private let viewModel = FavoriteListViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.placeholder = "즐겨찾기 검색"
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

    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "즐겨찾기가 없습니다"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.isHidden = true
        return label
    }()

    private var dataSource: UICollectionViewDiffableDataSource<CollectionSection, FavoriteBook>!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDataSource()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadFavorites()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "즐겨찾기"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        setupNavigationBarButtons()

        view.addSubview(collectionView)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupNavigationBarButtons() {
        let sortButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down"),
            style: .plain,
            target: self,
            action: #selector(sortButtonTapped)
        )

        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            style: .plain,
            target: self,
            action: #selector(filterButtonTapped)
        )

        navigationItem.rightBarButtonItems = [filterButton, sortButton]
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
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, FavoriteBook> { [weak self] cell, _, book in
            cell.contentConfiguration = UIHostingConfiguration {
                FavoriteCardView(
                    book: book,
                    onFavoriteTap: { [weak self] in
                        self?.viewModel.removeFavorite(book)
                    }
                )
            }
            .margins(.all, 0)
        }

        dataSource = UICollectionViewDiffableDataSource<CollectionSection, FavoriteBook>(
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
        viewModel.$filteredFavorites
            .receive(on: DispatchQueue.main)
            .sink { [weak self] books in
                self?.updateSnapshot(with: books)
                self?.emptyLabel.isHidden = !books.isEmpty
            }
            .store(in: &cancellables)
    }

    private func updateSnapshot(with books: [FavoriteBook]) {
        var snapshot = NSDiffableDataSourceSnapshot<CollectionSection, FavoriteBook>()
        snapshot.appendSections([CollectionSection.main])
        snapshot.appendItems(books)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - Actions

    @objc private func sortButtonTapped() {
        viewModel.toggleSort()

        let message = viewModel.sortAscending ? "제목 오름차순" : "제목 내림차순"
        showToast(message: message)
    }

    @objc private func filterButtonTapped() {
        let alert = UIAlertController(title: "가격 필터", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "전체", style: .default) { [weak self] _ in
            self?.viewModel.setPriceFilter(nil)
        })
        alert.addAction(UIAlertAction(title: "$30 이하", style: .default) { [weak self] _ in
            self?.viewModel.setPriceFilter(30)
        })
        alert.addAction(UIAlertAction(title: "$50 이하", style: .default) { [weak self] _ in
            self?.viewModel.setPriceFilter(50)
        })
        alert.addAction(UIAlertAction(title: "$100 이하", style: .default) { [weak self] _ in
            self?.viewModel.setPriceFilter(100)
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alert, animated: true)
    }

    private func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = .systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 8
        toastLabel.clipsToBounds = true
        toastLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(toastLabel)

        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            toastLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            toastLabel.heightAnchor.constraint(equalToConstant: 36)
        ])

        toastLabel.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

        UIView.animate(withDuration: 0.3, animations: {
            toastLabel.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.5, animations: {
                toastLabel.alpha = 0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
}

// MARK: - UISearchResultsUpdating

extension FavoriteListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.searchQuery = searchController.searchBar.text ?? ""
    }
}

// MARK: - UICollectionViewDelegate

extension FavoriteListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let book = dataSource.itemIdentifier(for: indexPath) else { return }

        let detailVC = BookDetailViewController(isbn13: book.id)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
