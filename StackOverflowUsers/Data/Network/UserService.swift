import Foundation

// MARK: - UserServiceProtocol

protocol UserServiceProtocol: Sendable {
    func fetchTopUsers() async throws -> [User]
}

// MARK: - UserService

final class UserService: UserServiceProtocol {

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    // MARK: - Endpoint

    private var topUsersURL: URL {
        var components = URLComponents(string: "https://api.stackexchange.com/2.2/users")!
        components.queryItems = [
            URLQueryItem(name: "page",     value: "1"),
            URLQueryItem(name: "pagesize", value: "20"),
            URLQueryItem(name: "order",    value: "desc"),
            URLQueryItem(name: "sort",     value: "reputation"),
            URLQueryItem(name: "site",     value: "stackoverflow")
        ]
        return components.url!
    }

    // MARK: - Fetch

    func fetchTopUsers() async throws -> [User] {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: topUsersURL)
        } catch let urlError as URLError {
            throw Self.mapURLError(urlError)
        } catch {
            throw AppError.networkUnavailable
        }

        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            throw AppError.serverError(http.statusCode)
        }

        let wrapper: StackExchangeResponse<User>
        do {
            wrapper = try decoder.decode(StackExchangeResponse<User>.self, from: data)
        } catch {
            throw AppError.decodingError
        }

        if wrapper.isAPIError {
            throw AppError.apiError(
                id: wrapper.errorId ?? 0,
                name: wrapper.errorName ?? "unknown_error",
                message: wrapper.errorMessage ?? "An unknown API error occurred."
            )
        }

        guard let users = wrapper.items, !users.isEmpty else {
            throw AppError.noResults
        }

        return users.map(Self.sanitize)
    }

    // MARK: - Mapping

    private static func sanitize(_ user: User) -> User {
        User(
            userId:       user.userId,
            displayName:  user.displayName.decodingHTMLEntities,
            reputation:   user.reputation,
            profileImage: user.profileImage,
            location:     user.location?.decodingHTMLEntities,
            link:         user.link,
            badgeCounts:  user.badgeCounts,
            acceptRate:   user.acceptRate
        )
    }

    private static func mapURLError(_ error: URLError) -> AppError {
        switch error.code {
        case .notConnectedToInternet,
             .networkConnectionLost,
             .cannotFindHost,
             .cannotConnectToHost,
             .timedOut,
             .dnsLookupFailed,
             .dataNotAllowed,
             .internationalRoamingOff:
            return .networkUnavailable
        default:
            return .networkUnavailable
        }
    }
}
