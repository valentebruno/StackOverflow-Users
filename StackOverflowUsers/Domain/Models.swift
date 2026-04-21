import Foundation

// MARK: - StackExchangeResponse

struct StackExchangeResponse<T: Decodable>: Decodable {
    let items: [T]?
    let hasMore: Bool?
    let quotaMax: Int?
    let quotaRemaining: Int?
    let errorId: Int?
    let errorMessage: String?
    let errorName: String?

    enum CodingKeys: String, CodingKey {
        case items
        case hasMore        = "has_more"
        case quotaMax       = "quota_max"
        case quotaRemaining = "quota_remaining"
        case errorId        = "error_id"
        case errorMessage   = "error_message"
        case errorName      = "error_name"
    }

    var isAPIError: Bool { errorId != nil }
}

// MARK: - User

struct User: Decodable, Hashable {
    let userId: Int
    let displayName: String
    let reputation: Int
    let profileImage: URL?
    let location: String?
    let link: URL?
    let badgeCounts: BadgeCounts?
    let acceptRate: Int?

    enum CodingKeys: String, CodingKey {
        case userId       = "user_id"
        case displayName  = "display_name"
        case reputation
        case profileImage = "profile_image"
        case location
        case link
        case badgeCounts  = "badge_counts"
        case acceptRate   = "accept_rate"
    }
}

// MARK: - BadgeCounts

struct BadgeCounts: Decodable, Hashable {
    let gold: Int?
    let silver: Int?
    let bronze: Int?
}

// MARK: - String + HTML Entities

extension String {
    var decodingHTMLEntities: String {
        let wrapped = "<meta charset=\"utf-8\">\(self)"
        guard let data = wrapped.data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        return (try? NSAttributedString(
            data: data,
            options: options,
            documentAttributes: nil
        ).string) ?? self
    }
}

// MARK: - AppError

enum AppError: Error, Equatable {
    case networkUnavailable
    case serverError(Int)
    case apiError(id: Int, name: String, message: String)
    case decodingError
    case noResults

    var userFacingMessage: String {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Check your network and try again."
        case .serverError(let code):
            return "The server returned an error (\(code)). Try again shortly."
        case .apiError(_, let name, let message):
            return "API error — \(name): \(message)"
        case .decodingError:
            return "Couldn't read the server response."
        case .noResults:
            return "No users found. Try again later."
        }
    }
}
