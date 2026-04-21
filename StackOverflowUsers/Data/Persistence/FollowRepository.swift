import Foundation
import os

// MARK: - FollowRepositoryProtocol

protocol FollowRepositoryProtocol: Sendable {
    func followedUserIDs() async -> Set<Int>
    func isFollowing(userID: Int) async -> Bool
    func follow(userID: Int) async
    func unfollow(userID: Int) async
    func toggle(userID: Int) async -> Bool
}

// MARK: - UserDefaultsFollowRepository

final class UserDefaultsFollowRepository: FollowRepositoryProtocol {

    private static let storageKey = "followed_user_ids"

    private let defaults: UserDefaults
    private let state: OSAllocatedUnfairLock<Set<Int>>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = (defaults.array(forKey: Self.storageKey) as? [Int]) ?? []
        self.state = OSAllocatedUnfairLock(initialState: Set(stored))
    }

    // MARK: - Reads

    func followedUserIDs() async -> Set<Int> {
        state.withLock { $0 }
    }

    func isFollowing(userID: Int) async -> Bool {
        state.withLock { $0.contains(userID) }
    }

    // MARK: - Writes

    func follow(userID: Int) async {
        let updated = state.withLock { ids -> Set<Int> in
            ids.insert(userID)
            return ids
        }
        persist(updated)
    }

    func unfollow(userID: Int) async {
        let updated = state.withLock { ids -> Set<Int> in
            ids.remove(userID)
            return ids
        }
        persist(updated)
    }

    @discardableResult
    func toggle(userID: Int) async -> Bool {
        let (updated, isFollowing) = state.withLock { ids -> (Set<Int>, Bool) in
            if ids.contains(userID) {
                ids.remove(userID)
                return (ids, false)
            } else {
                ids.insert(userID)
                return (ids, true)
            }
        }
        persist(updated)
        return isFollowing
    }

    // MARK: - Persistence

    private func persist(_ ids: Set<Int>) {
        defaults.set(Array(ids), forKey: Self.storageKey)
    }
}
