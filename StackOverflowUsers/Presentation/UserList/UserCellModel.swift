import Foundation

// MARK: - UserCellModel

struct UserCellModel: Hashable, Sendable {

    let userID: Int
    let displayName: String
    let profileImageURL: URL?
    let reputation: Int
    let isFollowed: Bool

    var formattedReputation: String {
        Self.formatter.string(from: NSNumber(value: reputation))
            .map { "\($0) rep" } ?? "\(reputation) rep"
    }

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}
