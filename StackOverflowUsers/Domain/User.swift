import Foundation

// MARK: - User

struct User: Decodable, Hashable, Sendable {
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

struct BadgeCounts: Decodable, Hashable, Sendable {
    let gold: Int?
    let silver: Int?
    let bronze: Int?
}
