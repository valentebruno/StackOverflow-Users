import Foundation

// MARK: - UserCacheProtocol

protocol UserCacheProtocol: Sendable {
    func load() async -> [User]?
    func save(_ users: [User]) async
    func clear() async
}

// MARK: - FileUserCache

final class FileUserCache: UserCacheProtocol, @unchecked Sendable {

    private let fileURL: URL
    private let fileManager: FileManager
    private let queue = DispatchQueue(label: "com.brunovalente.StackOverflowUsers.FileUserCache", qos: .utility)

    init(
        fileManager: FileManager = .default,
        directory: URL? = nil,
        fileName: String = "top-users.json"
    ) {
        self.fileManager = fileManager
        let baseURL = directory ?? Self.defaultDirectory(fileManager: fileManager)
        self.fileURL = baseURL.appendingPathComponent(fileName)
        try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    private static func defaultDirectory(fileManager: FileManager) -> URL {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return caches.appendingPathComponent("StackOverflowUsers", isDirectory: true)
    }

    // MARK: - Load

    func load() async -> [User]? {
        await withCheckedContinuation { continuation in
            queue.async { [fileURL, fileManager] in
                guard fileManager.fileExists(atPath: fileURL.path),
                      let data = try? Data(contentsOf: fileURL),
                      let users = try? JSONDecoder().decode([User].self, from: data) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: users)
            }
        }
    }

    // MARK: - Save

    func save(_ users: [User]) async {
        await withCheckedContinuation { continuation in
            queue.async { [fileURL] in
                if let data = try? JSONEncoder().encode(users) {
                    try? data.write(to: fileURL, options: .atomic)
                }
                continuation.resume()
            }
        }
    }

    // MARK: - Clear

    func clear() async {
        await withCheckedContinuation { continuation in
            queue.async { [fileURL, fileManager] in
                try? fileManager.removeItem(at: fileURL)
                continuation.resume()
            }
        }
    }
}
