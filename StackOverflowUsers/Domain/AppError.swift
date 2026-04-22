import Foundation

// MARK: - AppError

enum AppError: Error, Equatable, Sendable {

    case networkUnavailable
    case serverError(Int)
    case apiError(id: Int, name: String, message: String)
    case decodingError
    case noResults

    var userFacingMessage: String {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Check your network and try again."
        case .serverError(let code):
            return "The server returned an error (\(code)). Try again shortly."
        case .apiError:
            return "The request could not be completed. Try again later."
        case .decodingError:
            return "Couldn't read the server response."
        case .noResults:
            return "No users found. Try again later."
        }
    }
}
