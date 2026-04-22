import UIKit

// MARK: - InitialsImageGenerator

enum InitialsImageGenerator {

    static func image(for name: String, size: CGSize = CGSize(width: 44, height: 44)) -> UIImage {
        let initials = Self.initials(from: name)
        let (background, foreground) = Self.palette(for: initials)

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            context.cgContext.setFillColor(background.cgColor)
            context.cgContext.fillEllipse(in: rect)

            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: foreground,
                .font: UIFont.systemFont(ofSize: size.height * 0.4, weight: .semibold)
            ]
            let attributed = NSAttributedString(string: initials, attributes: attributes)
            let textSize = attributed.size()
            let textRect = CGRect(
                x: (size.width  - textSize.width)  / 2,
                y: (size.height - textSize.height) / 2,
                width:  textSize.width,
                height: textSize.height
            )
            attributed.draw(in: textRect)
        }
    }

    // MARK: - Helpers

    private static func initials(from name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "?" }

        let words = trimmed.split(separator: " ").prefix(2)
        let letters = words.compactMap { $0.first }.map(String.init)
        return letters.joined().uppercased()
    }

    private static let swatches: [(UIColor, UIColor)] = [
        (StackOverflowPalette.blue400, StackOverflowPalette.onStrongColor),
        (StackOverflowPalette.orange400, StackOverflowPalette.onStrongColor),
        (StackOverflowPalette.black500, StackOverflowPalette.onStrongColor),
        (StackOverflowPalette.black400, StackOverflowPalette.onStrongColor),
        (StackOverflowPalette.red400, StackOverflowPalette.onStrongColor),
        (StackOverflowPalette.green400, StackOverflowPalette.onStrongColor),
        (StackOverflowPalette.yellow400, StackOverflowPalette.black600),
        (StackOverflowPalette.bronze300, StackOverflowPalette.onStrongColor)
    ]

    private static func palette(for seed: String) -> (UIColor, UIColor) {
        let hash = seed.unicodeScalars.reduce(UInt32(0)) { acc, scalar in
            acc &* 31 &+ scalar.value
        }
        return swatches[Int(hash % UInt32(swatches.count))]
    }
}
