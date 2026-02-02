import UIKit
import SwiftUI

final class BookDetailViewController: UIHostingController<BookDetailView> {

    init(isbn13: String) {
        let viewModel = BookDetailViewModel(isbn13: isbn13)
        let detailView = BookDetailView(viewModel: viewModel)
        super.init(rootView: detailView)
    }

    @MainActor
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
