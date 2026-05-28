import SwiftUI

extension Color {
    // 主色板
    static let dlLavender = Color(red: 142 / 255, green: 106 / 255, blue: 255 / 255)
    static let dlLavenderSoft = Color(red: 217 / 255, green: 208 / 255, blue: 255 / 255)
    static let dlLilac = Color(red: 238 / 255, green: 230 / 255, blue: 255 / 255)
    static let dlRoseMist = Color(red: 248 / 255, green: 221 / 255, blue: 244 / 255)
    static let dlPlum = Color(red: 182 / 255, green: 156 / 255, blue: 255 / 255)
    static let dlVioletDeep = Color(red: 100 / 255, green: 68 / 255, blue: 210 / 255)
    static let dlGlassWhite = Color.white.opacity(0.56)
    static let dlGlassStroke = Color.white.opacity(0.58)

    // 功能色
    static let dlCoin = Color(red: 246 / 255, green: 201 / 255, blue: 72 / 255)
    static let dlSuccess = Color(red: 53 / 255, green: 200 / 255, blue: 137 / 255)
    static let dlWarning = Color(red: 255 / 255, green: 180 / 255, blue: 84 / 255)
    static let dlError = Color(red: 255 / 255, green: 127 / 255, blue: 155 / 255)

    // 文字色
    static let dlTextPrimary = Color(red: 39 / 255, green: 33 / 255, blue: 53 / 255)
    static let dlTextSecondary = Color(red: 95 / 255, green: 88 / 255, blue: 116 / 255)

    // 向后兼容别名：保持旧代码不破
    static let dlPrimary = dlLavender
    static let dlSecondary = dlTextSecondary
    static let dlBackground = dlLilac
    static let dlCardBackground = dlGlassWhite
}
