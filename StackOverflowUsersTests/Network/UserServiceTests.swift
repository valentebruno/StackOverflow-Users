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

    // MARK: - Success

    func test_fetchTopUsers_onSuccess_returnsDecodedAndSanitizedUsers() async throws {
        MockURLProtocol.requestHandler = { _ in
            (Fixtures.httpResponse(), Fixtures.data(Fixtures.successUsers))
        }

        let users = try await service.fetchTopUsers()

        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[0].displayName, "Jon Skeet")
        XCTAssertEqual(users[1].displayName, "Salvadór")
        XCTAssertEqual(users[1].location, "Curaçao")
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
            _ = try await service.fetchTopUsers()
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

    private func assertThrows(_ expected: AppError, file: StaticString = #filePath, line: UInt = #line) async {
        do {
            _ = try await service.fetchTopUsers()
            XCTFail("Expected to throw \(expected)", file: file, line: line)
        } catch let error as AppError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Unexpected error \(error)", file: file, line: line)
        }
    }
}
