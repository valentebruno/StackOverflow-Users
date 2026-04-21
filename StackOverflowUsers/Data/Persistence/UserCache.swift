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
    private let queue = DispatchQueue(label: "com.brunovalente.StackOverflowUsers.FileUserCache", qos: .utility)

    init(
        directory: URL? = nil,
        fileName: String = "top-users.json"
    ) {
        let baseURL = directory ?? Self.defaultDirectory()
        self.fileURL = baseURL.appendingPathComponent(fileName)
        try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    private static func defaultDirectory() -> URL {
        let fm = FileManager.default
        let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fm.temporaryDirectory
        return caches.appendingPathComponent("StackOverflowUsers", isDirectory: true)
    }

    // MARK: - Load

    func load() async -> [User]? {
        await withCheckedContinuation { continuation in
            queue.async { [fileURL] in
                let fm = FileManager.default
                guard fm.fileExists(atPath: fileURL.path),
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
            queue.async { [fileURL] in
                try? FileManager.default.removeItem(at: fileURL)
                continuation.resume()
            }
        }
    }
}
