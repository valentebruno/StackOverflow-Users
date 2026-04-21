import XCTest
@testable import StackOverflowUsers

// MARK: - DecodingTests

final class DecodingTests: XCTestCase {

    private let decoder = JSONDecoder()

    // MARK: - Wrapper

    func test_successWrapper_decodesItemsAndMetadata() throws {
        let wrapper = try decode(Fixtures.successUsers)

        XCTAssertEqual(wrapper.items?.count, 2)
        XCTAssertEqual(wrapper.hasMore, false)
        XCTAssertEqual(wrapper.quotaMax, 300)
        XCTAssertEqual(wrapper.quotaRemaining, 299)
        XCTAssertFalse(wrapper.isAPIError)
    }

    func test_apiErrorWrapper_decodesErrorFields() throws {
        let wrapper = try decode(Fixtures.apiErrorWrapper)

        XCTAssertTrue(wrapper.isAPIError)
        XCTAssertEqual(wrapper.errorId, 502)
        XCTAssertEqual(wrapper.errorName, "throttle_violation")
        XCTAssertNotNil(wrapper.errorMessage)
        XCTAssertNil(wrapper.items)
    }

    func test_emptyItemsWrapper_decodesAsEmpty() throws {
        let wrapper = try decode(Fixtures.emptyItems)
        XCTAssertEqual(wrapper.items?.isEmpty, true)
        XCTAssertFalse(wrapper.isAPIError)
    }

    func test_malformedJSON_throws() {
        XCTAssertThrowsError(try decode(Fixtures.malformed))
    }

    // MARK: - User

    func test_user_decodesBadgeCountsAsIntegers() throws {
        let wrapper = try decode(Fixtures.successUsers)
        let jon = try XCTUnwrap(wrapper.items?.first)
        XCTAssertEqual(jon.badgeCounts?.bronze, 9527)
        XCTAssertEqual(jon.badgeCounts?.silver, 8499)
        XCTAssertEqual(jon.badgeCounts?.gold, 888)
    }

    func test_user_withoutAcceptRate_decodesSuccessfully() throws {
        let wrapper = try decode(Fixtures.successUsers)
        let second = try XCTUnwrap(wrapper.items?.last)
        XCTAssertNil(second.acceptRate)
    }

    func test_user_minimalFields_decodesWithOptionalsNil() throws {
        let wrapper = try decode(Fixtures.minimalUser)
        let bot = try XCTUnwrap(wrapper.items?.first)

        XCTAssertEqual(bot.userId, 1)
        XCTAssertEqual(bot.displayName, "Bot")
        XCTAssertNil(bot.profileImage)
        XCTAssertNil(bot.location)
        XCTAssertNil(bot.acceptRate)
        XCTAssertNil(bot.badgeCounts)
    }

    // MARK: - HTML Entities

    func test_htmlEntities_decodeAccentedCharacters() {
        XCTAssertEqual("Salvad&#243;r".decodingHTMLEntities, "Salvadór")
        XCTAssertEqual("Cura&#231;ao".decodingHTMLEntities, "Curaçao")
    }

    func test_htmlEntities_onPlainText_returnsUnchanged() {
        XCTAssertEqual("Jon Skeet".decodingHTMLEntities, "Jon Skeet")
    }

    // MARK: - Helpers

    private func decode(_ json: String) throws -> StackExchangeResponse<User> {
        try decoder.decode(StackExchangeResponse<User>.self, from: Fixtures.data(json))
    }
}
