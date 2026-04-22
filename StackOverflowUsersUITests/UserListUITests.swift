import XCTest

// MARK: - UserListUITests

final class UserListUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITests"]
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Launch

    func test_launch_showsTopUsers() {
        app.launch()

        let jon    = app.cells["user-cell-101"]
        let gordon = app.cells["user-cell-202"]
        let vonc   = app.cells["user-cell-303"]

        XCTAssertTrue(jon.waitForExistence(timeout: 5))
        XCTAssertTrue(gordon.exists)
        XCTAssertTrue(vonc.exists)
        XCTAssertTrue(jon.staticTexts["Jon Skeet"].exists)
    }

    func test_launch_whenServerUnavailable_showsErrorEmptyState() {
        app.launchArguments = ["-UITests", "-UITests-FailNetwork"]
        app.launch()

        let emptyTitle = app.staticTexts["empty-state-title"]
        XCTAssertTrue(emptyTitle.waitForExistence(timeout: 5))
        XCTAssertEqual(emptyTitle.label, "You're offline")
        XCTAssertTrue(app.buttons["Try Again"].exists)
        XCTAssertFalse(app.cells["user-cell-101"].exists)
    }

    // MARK: - Follow toggle

    func test_tappingFollow_showsUnfollowStateAndIndicator() {
        app.launch()

        let cell = app.cells["user-cell-101"]
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        XCTAssertTrue(cell.label.contains("Not followed"),
                      "Cell should start as not followed, got: \(cell.label)")

        cell.buttons["Follow Jon Skeet"].tap()

        let unfollowButton = cell.buttons["Unfollow Jon Skeet"]
        XCTAssertTrue(unfollowButton.waitForExistence(timeout: 2))

        // The cell's composed accessibility label reflects followed state for VoiceOver
        // users; asserting on that is more stable than peeking at the indicator image,
        // which UIStackView sometimes keeps out of the accessibility tree.
        let refreshedCell = app.cells["user-cell-101"]
        XCTAssertTrue(refreshedCell.label.contains("Followed"),
                      "Cell should announce Followed state, got: \(refreshedCell.label)")
    }

    // MARK: - Filter

    func test_filterToFollowed_whenNobodyFollowed_showsEmptyState() {
        app.launch()
        XCTAssertTrue(app.cells["user-cell-101"].waitForExistence(timeout: 5))

        selectFollowedFilter()

        let emptyTitle = app.staticTexts["empty-state-title"]
        XCTAssertTrue(emptyTitle.waitForExistence(timeout: 2))
        XCTAssertEqual(emptyTitle.label, "No followed users yet")

        let allSegment = app.buttons["All"]
        XCTAssertTrue(allSegment.exists, "The filter should remain visible in the Followed empty state")
        allSegment.tap()

        XCTAssertTrue(app.cells["user-cell-101"].waitForExistence(timeout: 2))
    }

    func test_filterToFollowed_afterFollowing_showsOnlyFollowedUsers() {
        app.launch()

        let jonCell = app.cells["user-cell-101"]
        XCTAssertTrue(jonCell.waitForExistence(timeout: 5))
        jonCell.buttons["Follow Jon Skeet"].tap()

        selectFollowedFilter()

        XCTAssertTrue(app.cells["user-cell-101"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.cells["user-cell-202"].exists)
        XCTAssertFalse(app.cells["user-cell-303"].exists)
    }

    // MARK: - Detail navigation

    func test_tappingCell_pushesDetailScreenWithProfileAction() {
        app.launch()

        let cell = app.cells["user-cell-101"]
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        cell.staticTexts["Jon Skeet"].tap()

        // Push animation
        let navBar = app.navigationBars["Jon Skeet"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 3))

        let openProfile = app.buttons["open-profile-button"]
        XCTAssertTrue(openProfile.waitForExistence(timeout: 2))
        XCTAssertTrue(openProfile.isHittable)
    }

    // MARK: - Helpers

    private func selectFollowedFilter() {
        let followedSegment = app.buttons["Followed"]
        XCTAssertTrue(followedSegment.waitForExistence(timeout: 2))
        followedSegment.tap()
    }
}
