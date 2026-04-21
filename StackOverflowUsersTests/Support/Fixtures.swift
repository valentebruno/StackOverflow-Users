import Foundation
@testable import StackOverflowUsers

// MARK: - Fixtures

enum Fixtures {

    // MARK: - JSON strings

    static let successUsers = """
    {
        "items": [
            {
                "user_id": 22656,
                "display_name": "Jon Skeet",
                "reputation": 1454978,
                "profile_image": "https://example.com/jon.png",
                "location": "Reading, United Kingdom",
                "link": "https://stackoverflow.com/users/22656/jon-skeet",
                "badge_counts": { "bronze": 9527, "silver": 8499, "gold": 888 },
                "accept_rate": 85
            },
            {
                "user_id": 29407,
                "display_name": "Salvad&#243;r",
                "reputation": 987654,
                "profile_image": "https://example.com/salvador.png",
                "location": "Cura&#231;ao",
                "link": "https://stackoverflow.com/users/29407/salvador",
                "badge_counts": { "bronze": 10, "silver": 20, "gold": 5 }
            }
        ],
        "has_more": false,
        "quota_max": 300,
        "quota_remaining": 299
    }
    """

    static let apiErrorWrapper = """
    {
        "error_id": 502,
        "error_message": "too many requests from this IP, more requests available in 33635 seconds",
        "error_name": "throttle_violation"
    }
    """

    static let minimalUser = """
    {
        "items": [
            {
                "user_id": 1,
                "display_name": "Bot",
                "reputation": 0,
                "link": "https://stackoverflow.com/users/1/bot"
            }
        ]
    }
    """

    static let emptyItems = """
    { "items": [], "has_more": false }
    """

    static let malformed = "{ this is not valid json"

    // MARK: - Helpers

    static func data(_ json: String) -> Data {
        json.data(using: .utf8)!
    }

    static func httpResponse(statusCode: Int = 200, url: URL = URL(string: "https://api.stackexchange.com/2.2/users")!) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: nil)!
    }
}
