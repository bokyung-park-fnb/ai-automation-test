import Foundation
import Combine

protocol FavoriteRepositoryProtocol: Sendable {
    /// 모든 즐겨찾기 조회
    func fetchAllFavorites() -> AnyPublisher<[FavoriteBook], Error>

    /// 즐겨찾기 추가
    func addFavorite(_ book: FavoriteBook) -> AnyPublisher<Void, Error>

    /// 즐겨찾기 삭제
    func removeFavorite(isbn13: String) -> AnyPublisher<Void, Error>

    /// 즐겨찾기 여부 확인
    func isFavorite(isbn13: String) -> AnyPublisher<Bool, Error>

    /// 즐겨찾기 토글
    func toggleFavorite(_ book: FavoriteBook) -> AnyPublisher<Bool, Error>
}
