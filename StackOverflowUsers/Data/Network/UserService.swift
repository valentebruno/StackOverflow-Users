import Foundation

// MARK: - UserServiceProtocol

protocol UserServiceProtocol: Sendable {
    func fetchTopUsers(page: Int, pageSize: Int) async throws -> UserPage
}

// MARK: - UserService

final class UserService: UserServiceProtocol {

    private let session: URLSession
    private let decoder: JSONDecoder
    private let baseURL: URL

    init(
        session: URLSession = UserService.defaultSession(),
        baseURL: URL = URL(string: "https://api.stackexchange.com/2.2")!
    ) {
        self.session = session
        self.decoder = JSONDecoder()
        self.baseURL = baseURL
    }

    // MARK: - Session Factory

    static func defaultSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = false
        config.httpAdditionalHeaders = ["Accept": "application/json"]
        config.requestCachePolicy = .useProtocolCachePolicy
        config.urlCache = URLCache(
            memoryCapacity: 4 * 1024 * 1024,
            diskCapacity:   20 * 1024 * 1024
        )
        return URLSession(configuration: config)
    }

    // MARK: - Endpoint

    private func topUsersURL(page: Int, pageSize: Int) -> URL {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("users"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "page",     value: String(page)),
            URLQueryItem(name: "pagesize", value: String(pageSize)),
            URLQueryItem(name: "order",    value: "desc"),
            URLQueryItem(name: "sort",     value: "reputation"),
            URLQueryItem(name: "site",     value: "stackoverflow")
        ]
        return components.url!
    }

    // MARK: - Fetch

    func fetchTopUsers(page: Int, pageSize: Int) async throws -> UserPage {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: topUsersURL(page: page, pageSize: pageSize))
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
                id:      wrapper.errorId ?? 0,
                name:    wrapper.errorName ?? "unknown_error",
                message: wrapper.errorMessage ?? "An unknown API error occurred."
            )
        }

        let users = wrapper.items ?? []
        if page == 1 && users.isEmpty {
            throw AppError.noResults
        }

        return UserPage(
            users:   users.map(Self.sanitize),
            hasMore: wrapper.hasMore ?? false
        )
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
             .internationalRoamingOff,
             .callIsActive:
            return .networkUnavailable
        case .cancelled:
            return .networkUnavailable
        default:
            return .networkUnavailable
        }
    }
}
