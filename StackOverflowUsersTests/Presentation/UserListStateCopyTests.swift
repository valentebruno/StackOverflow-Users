import XCTest
@testable import StackOverflowUsers

// MARK: - UserListStateCopyTests

final class UserListStateCopyTests: XCTestCase {

    // MARK: - Empty reasons

    func test_emptyTitle_forNothingFollowed_isDistinct() {
        let title = UserListStateCopy.emptyTitle(for: .nothingFollowed)
        XCTAssertFalse(title.isEmpty)
        XCTAssertTrue(title.lowercased().contains("followed"))
    }

    func test_emptyMessage_forNothingFollowed_referencesTheFollowAction() {
        let message = UserListStateCopy.emptyMessage(for: .nothingFollowed)
        XCTAssertTrue(message.lowercased().contains("follow"))
    }

    // MARK: - Error titles

    func test_errorTitle_producesADistinctTitlePerCase() {
        let titles: [AppError] = [
            .networkUnavailable,
            .serverError(500),
            .apiError(id: 1, name: "x", message: "y"),
            .decodingError,
            .noResults
        ]
        let rendered = titles.map(UserListStateCopy.errorTitle(for:))
        XCTAssertEqual(Set(rendered).count, titles.count, "Every AppError should map to a unique title")
        rendered.forEach { XCTAssertFalse($0.isEmpty) }
    }

    func test_errorTitle_forNetworkUnavailable_mentionsOffline() {
        XCTAssertTrue(
            UserListStateCopy.errorTitle(for: .networkUnavailable)
                .lowercased().contains("offline")
        )
    }

    func test_errorTitle_forDecodingError_doesNotLeakTechnicalTerms() {
        let title = UserListStateCopy.errorTitle(for: .decodingError)
        XCTAssertFalse(title.lowercased().contains("decod"))
        XCTAssertFalse(title.lowercased().contains("json"))
        XCTAssertFalse(title.lowercased().contains("codable"))
    }
}
