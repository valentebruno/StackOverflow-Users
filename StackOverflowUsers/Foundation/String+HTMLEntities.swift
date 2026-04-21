import Foundation

// MARK: - String + HTML Entities

extension String {

    var decodingHTMLEntities: String {
        let wrapped = "<meta charset=\"utf-8\">\(self)"
        guard let data = wrapped.data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType:      NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        return (try? NSAttributedString(
            data: data,
            options: options,
            documentAttributes: nil
        ).string) ?? self
    }
}
