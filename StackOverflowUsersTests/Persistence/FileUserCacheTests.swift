import XCTest
@testable import StackOverflowUsers

// MARK: - FileUserCacheTests

final class FileUserCacheTests: XCTestCase {

    private var directory: URL!
    private var cache: FileUserCache!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileUserCacheTests-\(UUID().uuidString)", isDirectory: true)
        cache = FileUserCache(directory: directory, fileName: "users.json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        cache = nil
        directory = nil
        super.tearDown()
    }

    // MARK: - Round trip

    func test_saveThenLoad_returnsTheSameUsers() async {
        let users = [User.fixture(userId: 1, displayName: "Ann"), User.fixture(userId: 2, displayName: "Bob")]
        await cache.save(users)

        let loaded = await cache.load()

        XCTAssertEqual(loaded?.map(\.userId), [1, 2])
    }

    func test_loadWithoutSave_returnsNil() async {
        let loaded = await cache.load()
        XCTAssertNil(loaded)
    }

    func test_clear_removesTheCachedFile() async {
        await cache.save([.fixture(userId: 42)])
        await cache.clear()

        let loaded = await cache.load()
        XCTAssertNil(loaded)
    }

    func test_saveOverwritesPreviousContent() async {
        await cache.save([.fixture(userId: 1)])
        await cache.save([.fixture(userId: 99, displayName: "Newer")])

        let loaded = await cache.load()
        XCTAssertEqual(loaded?.map(\.userId), [99])
    }
}
