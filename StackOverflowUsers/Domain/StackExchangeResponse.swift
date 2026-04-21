import Foundation

// MARK: - StackExchangeResponse

struct StackExchangeResponse<T: Decodable & Sendable>: Decodable, Sendable {

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
