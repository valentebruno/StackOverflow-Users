import UIKit

// MARK: - StackOverflowPalette

enum StackOverflowPalette {

    // MARK: - Brand stops

    static let orange400 = UIColor(hex: 0xF48024)
    static let blue400 = UIColor(hex: 0x0095FF)
    static let yellow400 = UIColor(hex: 0xFFB500)
    static let black600 = UIColor(hex: 0x242729)
    static let black300 = UIColor(hex: 0xBBC0C4)

    // MARK: - Product stops

    static let black050 = UIColor(hex: 0xF8F9F9)
    static let black100 = UIColor(hex: 0xF1F2F3)
    static let black200 = UIColor(hex: 0xE3E6E8)
    static let black400 = UIColor(hex: 0x6A737C)
    static let black500 = UIColor(hex: 0x3B4045)
    static let red400 = UIColor(hex: 0xD0393E)
    static let green400 = UIColor(hex: 0x2F6F44)
    static let bronze300 = UIColor(hex: 0xC38B5F)

    // MARK: - Semantic colors

    static let appBackground = UIColor(light: black050, dark: .black)
    static let contentBackground = UIColor(light: .white, dark: black600)
    static let componentBackground = UIColor(light: black100, dark: black500)
    static let componentAltBackground = UIColor(light: black200, dark: black400)
    static let separator = UIColor(light: black200, dark: black500)
    static let textPrimary = UIColor(light: black600, dark: black050)
    static let textSecondary = UIColor(light: black400, dark: black300)
    static let textTertiary = UIColor(light: black300, dark: black400)
    static let primaryAction = UIColor(light: blue400, dark: blue400)
    static let accent = UIColor(light: orange400, dark: orange400)
    static let danger = UIColor(light: red400, dark: red400)
    static let success = UIColor(light: green400, dark: green400)
    static let warningBackground = UIColor(light: yellow400, dark: orange400)
    static let onStrongColor = UIColor.white
}

private extension UIColor {

    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    convenience init(light: UIColor, dark: UIColor) {
        self.init { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
    }
}
