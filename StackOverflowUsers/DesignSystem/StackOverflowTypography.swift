import UIKit

// MARK: - StackOverflowTypography

enum StackOverflowTypography {

    enum Scale {
        case fine
        case caption
        case body1
        case body2
        case body3
        case subheading
        case title
        case headline1
        case headline2
        case display1
        case display2
        case display3
        case display4
        case category

        var pointSize: CGFloat {
            switch self {
            case .fine:       return 11
            case .caption:    return 12
            case .body1:      return 13
            case .body2:      return 15
            case .body3:      return 17
            case .subheading: return 19
            case .title:      return 21
            case .headline1:  return 27
            case .headline2:  return 34
            case .display1:   return 43
            case .display2:   return 55
            case .display3:   return 69
            case .display4:   return 99
            case .category:   return 12
            }
        }

        var textStyle: UIFont.TextStyle {
            switch self {
            case .fine:       return .caption2
            case .caption,
                 .category:   return .caption1
            case .body1:      return .footnote
            case .body2:      return .subheadline
            case .body3:      return .body
            case .subheading: return .title3
            case .title:      return .title2
            case .headline1:  return .title1
            case .headline2,
                 .display1,
                 .display2,
                 .display3,
                 .display4:   return .largeTitle
            }
        }
    }

    static func font(_ scale: Scale, weight: UIFont.Weight = .regular) -> UIFont {
        let baseFont = UIFont.systemFont(ofSize: scale.pointSize, weight: weight)
        return UIFontMetrics(forTextStyle: scale.textStyle).scaledFont(for: baseFont)
    }

    static func apply(
        _ scale: Scale,
        weight: UIFont.Weight = .regular,
        to label: UILabel
    ) {
        label.font = font(scale, weight: weight)
        label.adjustsFontForContentSizeCategory = true
    }

    static func textAttributes(
        _ scale: Scale,
        weight: UIFont.Weight = .regular,
        color: UIColor? = nil
    ) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font(scale, weight: weight)
        ]
        if let color {
            attributes[.foregroundColor] = color
        }
        return attributes
    }

    static func buttonTextTransformer(
        _ scale: Scale,
        weight: UIFont.Weight = .medium,
        color: UIColor? = nil
    ) -> UIConfigurationTextAttributesTransformer {
        UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = font(scale, weight: weight)
            if let color {
                outgoing.foregroundColor = color
            }
            return outgoing
        }
    }
}
