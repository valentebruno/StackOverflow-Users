import UIKit

// MARK: - ImageLoading

protocol ImageLoading: Sendable {
    func image(for url: URL) async -> UIImage?
    func clear() async
}
