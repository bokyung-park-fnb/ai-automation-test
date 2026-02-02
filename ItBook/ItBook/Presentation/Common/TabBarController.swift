import UIKit

final class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupAppearance()
    }

    private func setupViewControllers() {
        let searchListVC = SearchListViewController()
        let searchNavController = UINavigationController(rootViewController: searchListVC)
        searchNavController.tabBarItem = UITabBarItem(
            title: "검색",
            image: UIImage(systemName: "magnifyingglass"),
            selectedImage: UIImage(systemName: "magnifyingglass.circle.fill")
        )

        let favoriteListVC = FavoriteListViewController()
        let favoriteNavController = UINavigationController(rootViewController: favoriteListVC)
        favoriteNavController.tabBarItem = UITabBarItem(
            title: "즐겨찾기",
            image: UIImage(systemName: "star"),
            selectedImage: UIImage(systemName: "star.fill")
        )

        viewControllers = [searchNavController, favoriteNavController]
    }

    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
}
