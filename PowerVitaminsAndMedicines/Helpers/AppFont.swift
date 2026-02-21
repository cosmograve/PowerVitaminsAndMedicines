import SwiftUI
import UIKit

enum AppFont {

    enum Family {
        static let medium = "Poppins-Medium"
        static let regular = "Poppins-Regular"
        static let semibold = "Poppins-SemiBold"
        
    }

    enum Weight {
        case regular
        case medium
        case semibold
    }

    static func poppins(size: CGFloat, weight: Weight) -> Font {
        let name: String
        switch weight {
        case .regular: name = Family.regular
        case .medium:  name = Family.medium
        case .semibold: name = Family.semibold
        }

        return Font(uiFont: makeUIFont(name: name, size: size))
    }

    private static func makeUIFont(name: String, size: CGFloat) -> UIFont {
        if let custom = UIFont(name: name, size: size) {
            return custom
        }

        return UIFont.systemFont(ofSize: size, weight: .regular)
    }
}

extension Font {
    init(uiFont: UIFont) {
        self = Font(uiFont as CTFont)
    }
}
