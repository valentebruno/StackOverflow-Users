import Foundation

// MARK: - UserDetailViewModel

struct UserDetailViewModel: Equatable, Sendable {

    let user: User

    // MARK: - Display

    var displayName: String {
        user.displayName
    }

    var profileImageURL: URL? {
        user.profileImage
    }

    var formattedReputation: String {
        Self.reputationFormatter.string(from: NSNumber(value: user.reputation))
            .map { "\($0) reputation" } ?? "\(user.reputation) reputation"
    }

    var location: String? {
        guard let location = user.location?.trimmingCharacters(in: .whitespacesAndNewlines),
              !location.isEmpty else { return nil }
        return location
    }

    var profileURL: URL? {
        user.link
    }

    // MARK: - Badges

    var goldBadges: Int   { user.badgeCounts?.gold   ?? 0 }
    var silverBadges: Int { user.badgeCounts?.silver ?? 0 }
    var bronzeBadges: Int { user.badgeCounts?.bronze ?? 0 }

    var hasBadges: Bool {
        goldBadges + silverBadges + bronzeBadges > 0
    }

    // MARK: - Accept rate

    var formattedAcceptRate: String? {
        guard let rate = user.acceptRate else { return nil }
        return "\(rate)% accept rate"
    }

    // MARK: - Helpers

    private static let reputationFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}
