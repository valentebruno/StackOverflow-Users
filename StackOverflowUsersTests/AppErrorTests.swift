import XCTest
@testable import StackOverflowUsers

// MARK: - AppErrorTests

final class AppErrorTests: XCTestCase {

    func test_userFacingMessage_networkUnavailable_mentionsConnection() {
        let message = AppError.networkUnavailable.userFacingMessage
        XCTAssertTrue(message.localizedCaseInsensitiveContains("internet"))
    }

    func test_userFacingMessage_serverError_includesStatusCode() {
        let message = AppError.serverError(503).userFacingMessage
        XCTAssertTrue(message.contains("503"))
    }

    func test_userFacingMessage_apiError_includesNameAndMessage() {
        let error = AppError.apiError(id: 502, name: "throttle_violation", message: "slow down")
        let message = error.userFacingMessage
        XCTAssertTrue(message.contains("throttle_violation"))
        XCTAssertTrue(message.contains("slow down"))
    }

    func test_userFacingMessage_decodingError_isDistinctFromNetwork() {
        XCTAssertNotEqual(
            AppError.decodingError.userFacingMessage,
            AppError.networkUnavailable.userFacingMessage
        )
    }

    func test_userFacingMessage_noResults_mentionsUsers() {
        let message = AppError.noResults.userFacingMessage
        XCTAssertTrue(message.localizedCaseInsensitiveContains("user"))
    }

    // MARK: - Equality

    func test_equality_distinguishesServerErrorStatusCodes() {
        XCTAssertNotEqual(AppError.serverError(500), AppError.serverError(503))
    }

    func test_equality_distinguishesApiErrorIdentifiers() {
        let a = AppError.apiError(id: 1, name: "one", message: "m")
        let b = AppError.apiError(id: 2, name: "one", message: "m")
        XCTAssertNotEqual(a, b)
    }
}
