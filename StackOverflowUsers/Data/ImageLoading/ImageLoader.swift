import UIKit

// MARK: - ImageLoading

protocol ImageLoading: Sendable {
    func image(for url: URL) async -> UIImage?
    func clear() async
}

// MARK: - ImageLoader

actor ImageLoader: ImageLoading {

    static let shared = ImageLoader()

    private let session: URLSession
    private let cache = NSCache<NSURL, UIImage>()
    private var inFlight: [URL: Task<UIImage?, Never>] = [:]

    init(session: URLSession = .shared, countLimit: Int = 200, totalCostLimit: Int = 64 * 1024 * 1024) {
        self.session = session
        self.cache.countLimit = countLimit
        self.cache.totalCostLimit = totalCostLimit
    }

    // MARK: - Load

    func image(for url: URL) async -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }

        if let existing = inFlight[url] {
            return await existing.value
        }

        let task = Task<UIImage?, Never> { [session] in
            do {
                let (data, response) = try await session.data(from: url)
                if let http = response as? HTTPURLResponse,
                   !(200...299).contains(http.statusCode) {
                    return nil
                }
                guard let image = UIImage(data: data) else { return nil }
                return await Self.prepareForDisplay(image)
            } catch {
                return nil
            }
        }

        inFlight[url] = task
        let result = await task.value
        inFlight[url] = nil

        if let result {
            cache.setObject(result, forKey: url as NSURL, cost: Self.cost(of: result))
        }
        return result
    }

    func clear() {
        cache.removeAllObjects()
        for (_, task) in inFlight { task.cancel() }
        inFlight.removeAll()
    }

    // MARK: - Helpers

    private static func prepareForDisplay(_ image: UIImage) async -> UIImage {
        await Task.detached(priority: .utility) {
            image.preparingForDisplay() ?? image
        }.value
    }

    private static func cost(of image: UIImage) -> Int {
        guard let cg = image.cgImage else { return 0 }
        return cg.bytesPerRow * cg.height
    }
}
