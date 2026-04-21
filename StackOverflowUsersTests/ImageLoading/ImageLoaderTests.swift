import XCTest
import UIKit
@testable import StackOverflowUsers

// MARK: - ImageLoaderTests

final class ImageLoaderTests: XCTestCase {

    private var loader: ImageLoader!

    override func setUp() {
        super.setUp()
        loader = ImageLoader(session: MockNetworking.makeSession())
    }

    override func tearDown() async throws {
        MockURLProtocol.reset()
        await loader.clear()
        loader = nil
        try await super.tearDown()
    }

    // MARK: - Success

    func test_image_onSuccess_returnsDecodedImage() async throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/avatar.png"))
        let data = Self.pngData(color: .red)
        MockURLProtocol.requestHandler = { _ in
            (HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!, data)
        }

        let image = await loader.image(for: url)
        XCTAssertNotNil(image)
    }

    // MARK: - Errors

    func test_image_onHTTPError_returnsNil() async throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/missing.png"))
        MockURLProtocol.requestHandler = { _ in
            (HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!, Data())
        }

        let image = await loader.image(for: url)
        XCTAssertNil(image)
    }

    func test_image_onTransportError_returnsNil() async throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/unreachable.png"))
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let image = await loader.image(for: url)
        XCTAssertNil(image)
    }

    // MARK: - Cache

    func test_image_secondLoadHitsCache() async throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/cached.png"))
        let data = Self.pngData(color: .blue)
        let counter = Counter()

        MockURLProtocol.requestHandler = { _ in
            counter.bump()
            return (HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!, data)
        }

        _ = await loader.image(for: url)
        _ = await loader.image(for: url)

        XCTAssertEqual(counter.value, 1, "Second fetch should be served from cache")
    }

    // MARK: - Deduplication

    func test_image_concurrentRequestsForSameURLDedupe() async throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/once.png"))
        let data = Self.pngData(color: .green)
        let counter = Counter()

        MockURLProtocol.requestHandler = { _ in
            counter.bump()
            Thread.sleep(forTimeInterval: 0.1)
            return (HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!, data)
        }

        async let first  = loader.image(for: url)
        async let second = loader.image(for: url)
        _ = await (first, second)

        XCTAssertEqual(counter.value, 1, "Concurrent requests for the same URL should dedupe into one network call")
    }

    // MARK: - Helpers

    private static func pngData(color: UIColor) -> Data {
        UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
            .pngData { ctx in
                color.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            }
    }
}

// MARK: - Counter

private final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var _value = 0

    var value: Int {
        lock.lock(); defer { lock.unlock() }
        return _value
    }

    func bump() {
        lock.lock(); defer { lock.unlock() }
        _value += 1
    }
}
