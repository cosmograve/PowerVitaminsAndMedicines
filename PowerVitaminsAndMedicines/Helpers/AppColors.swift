import SwiftUI

// MARK: - Color + Hex

extension Color {

    /// Create SwiftUI Color from hex string.
    /// Supports: "RRGGBB", "#RRGGBB", "AARRGGBB", "#AARRGGBB".
    init(hex: String) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard cleaned.count == 6 || cleaned.count == 8 else {
            self = .clear
            return
        }

        var value: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&value) else {
            self = .clear
            return
        }

        let a, r, g, b: Double

        if cleaned.count == 8 {
            // AARRGGBB
            a = Double((value & 0xFF000000) >> 24) / 255.0
            r = Double((value & 0x00FF0000) >> 16) / 255.0
            g = Double((value & 0x0000FF00) >> 8) / 255.0
            b = Double(value & 0x000000FF) / 255.0
        } else {
            // RRGGBB
            a = 1.0
            r = Double((value & 0xFF0000) >> 16) / 255.0
            g = Double((value & 0x00FF00) >> 8) / 255.0
            b = Double(value & 0x0000FF) / 255.0
        }

        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - App Palette

enum AppColors {
    static let yellow = Color(hex: "FFCC00")
    static let background = Color(hex: "12110A")
    static let red = Color(hex: "F70000")
    static let gray = Color(hex: "4B4B4B")        
    static let green = Color(hex: "00841D")
    static let blue = Color(hex: "004153")
    static let cardSwamp = Color(hex: "27251B")
    static let textBlack = Color(hex: "27251B")
    static let tabBarBackground = Color(hex: "1C1C1C")
}
