import Foundation

// MARK: - FollowRepositoryProtocol

protocol FollowRepositoryProtocol: Sendable {
    func followedUserIDs() async -> Set<Int>
    func isFollowing(userID: Int) async -> Bool
    func follow(userID: Int) async
    func unfollow(userID: Int) async
    func toggle(userID: Int) async -> Bool
}
