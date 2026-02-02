import Foundation
import Combine

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingFailed(Error)
    case serverError(statusCode: Int)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingFailed(let error):
            return "Decoding failed: \(error.localizedDescription)"
        case .serverError(let statusCode):
            return "Server error: \(statusCode)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

protocol NetworkManagerProtocol: Sendable {
    func request<T: Decodable>(_ endpoint: String) -> AnyPublisher<T, Error>
}

final class NetworkManager: NetworkManagerProtocol, @unchecked Sendable {

    private let baseURL = "https://api.itbook.store/1.0"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<T: Decodable>(_ endpoint: String) -> AnyPublisher<T, Error> {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: url)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.noData
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.serverError(statusCode: httpResponse.statusCode)
                }

                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if let networkError = error as? NetworkError {
                    return networkError
                }
                if error is DecodingError {
                    return NetworkError.decodingFailed(error)
                }
                return NetworkError.unknown(error)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
