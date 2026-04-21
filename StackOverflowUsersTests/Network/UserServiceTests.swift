import XCTest
@testable import StackOverflowUsers

// MARK: - UserServiceTests

final class UserServiceTests: XCTestCase {

    private var service: UserService!

    override func setUp() {
        super.setUp()
        service = UserService(session: MockNetworking.makeSession())
    }

    override func tearDown() {
        MockURLProtocol.reset()
        service = nil
        super.tearDown()
    }

    // MARK: - Request shape

    func test_fetchTopUsers_buildsExpectedHTTPSRequest() async throws {
        let captured = CapturedRequest()
        MockURLProtocol.requestHandler = { request in
            captured.store(request)
            return (Fixtures.httpResponse(), Fixtures.data(Fixtures.successUsers))
        }

        _ = try await service.fetchTopUsers(page: 1, pageSize: 20)

        let request = try XCTUnwrap(captured.value)
        let url = try XCTUnwrap(request.url)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "api.stackexchange.com")
        XCTAssertEqual(components.path, "/2.2/users")

        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })
        XCTAssertEqual(items["page"],     "1")
        XCTAssertEqual(items["pagesize"], "20")
        XCTAssertEqual(items["order"],    "desc")
        XCTAssertEqual(items["sort"],     "reputation")
        XCTAssertEqual(items["site"],     "stackoverflow")
    }

    // MARK: - Success

    func test_fetchTopUsers_onSuccess_returnsDecodedAndSanitizedUsers() async throws {
        MockURLProtocol.requestHandler = { _ in
            (Fixtures.httpResponse(), Fixtures.data(Fixtures.successUsers))
        }

        let page = try await service.fetchTopUsers(page: 1, pageSize: 20)

        XCTAssertEqual(page.users.count, 2)
        XCTAssertEqual(page.users[0].displayName, "Jon Skeet")
        XCTAssertEqual(page.users[1].displayName, "Salvadór")
        XCTAssertEqual(page.users[1].location, "Curaçao")
        XCTAssertFalse(page.hasMore)
    }

    func test_fetchTopUsers_passesPageAndPageSizeToQueryItems() async throws {
        let captured = CapturedRequest()
        MockURLProtocol.requestHandler = { request in
            captured.store(request)
            return (Fixtures.httpResponse(), Fixtures.data(Fixtures.successUsers))
        }

        _ = try await service.fetchTopUsers(page: 3, pageSize: 50)

        let url = try XCTUnwrap(captured.value?.url)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })
        XCTAssertEqual(items["page"], "3")
        XCTAssertEqual(items["pagesize"], "50")
    }

    // MARK: - Errors

    func test_fetchTopUsers_onNon2xxHTTP_throwsServerError() async {
        MockURLProtocol.requestHandler = { _ in
            (Fixtures.httpResponse(statusCode: 500), Data())
        }

        await assertThrows(AppError.serverError(500))
    }

    func test_fetchTopUsers_onAPIErrorBody_throwsApiError() async {
        MockURLProtocol.requestHandler = { _ in
            (Fixtures.httpResponse(statusCode: 200), Fixtures.data(Fixtures.apiErrorWrapper))
        }

        do {
            _ = try await service.fetchTopUsers(page: 1, pageSize: 20)
            XCTFail("Expected apiError to throw")
        } catch let AppError.apiError(id, name, _) {
            XCTAssertEqual(id, 502)
            XCTAssertEqual(name, "throttle_violation")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_fetchTopUsers_onMalformedJSON_throwsDecodingError() async {
        MockURLProtocol.requestHandler = { _ in
            (Fixtures.httpResponse(), Fixtures.data(Fixtures.malformed))
        }

        await assertThrows(AppError.decodingError)
    }

    func test_fetchTopUsers_onEmptyItems_throwsNoResults() async {
        MockURLProtocol.requestHandler = { _ in
            (Fixtures.httpResponse(), Fixtures.data(Fixtures.emptyItems))
        }

        await assertThrows(AppError.noResults)
    }

    func test_fetchTopUsers_onTransportError_throwsNetworkUnavailable() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        await assertThrows(AppError.networkUnavailable)
    }

    // MARK: - Helpers

    // MARK: - CapturedRequest

    private final class CapturedRequest: @unchecked Sendable {
        private let lock = NSLock()
        private var _value: URLRequest?

        var value: URLRequest? {
            lock.lock(); defer { lock.unlock() }
            return _value
        }

        func store(_ request: URLRequest) {
            lock.lock(); defer { lock.unlock() }
            _value = request
        }
    }

    private func assertThrows(_ expected: AppError, file: StaticString = #filePath, line: UInt = #line) async {
        do {
            _ = try await service.fetchTopUsers(page: 1, pageSize: 20)
            XCTFail("Expected to throw \(expected)", file: file, line: line)
        } catch let error as AppError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Unexpected error \(error)", file: file, line: line)
        }
    }
}
