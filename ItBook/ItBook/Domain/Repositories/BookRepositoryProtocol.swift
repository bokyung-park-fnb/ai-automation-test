import Foundation
import Combine

protocol BookRepositoryProtocol: Sendable {
    /// 새로운 도서 목록 조회
    func fetchNewBooks() -> AnyPublisher<[Book], Error>

    /// 도서 검색
    func searchBooks(query: String, page: Int) -> AnyPublisher<(books: [Book], total: Int), Error>

    /// 도서 상세 정보 조회
    func fetchBookDetail(isbn13: String) -> AnyPublisher<BookDetail, Error>
}
