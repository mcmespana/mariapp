import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Paleta de Mariapp: base crema, molta calma, i tocs vitals de blau, verd, turquesa, groc i taronja.
/// Sense rosa ni roig (excepte la secció de metges, que ha de cridar l'atenció).
enum Paleta {
    // Superfícies
    static let fons = Color.dinamic(clar: 0xF7F1E6, fosc: 0x1C1A17)
    static let paper = Color.dinamic(clar: 0xFFFBF3, fosc: 0x272420)
    /// Part de dalt de la plastilina (una mica més clara que el paper).
    static let clayLlum = Color.dinamic(clar: 0xFFFEFA, fosc: 0x2F2B26)
    static let paperFosc = Color.dinamic(clar: 0xEFE6D4, fosc: 0x34302A)
    static let linia = Color.dinamic(clar: 0xE6DCC8, fosc: 0x3D3831)

    // Text
    static let tinta = Color.dinamic(clar: 0x3A352E, fosc: 0xF2EBDD)
    static let tintaSuau = Color.dinamic(clar: 0x8A8170, fosc: 0xA79F8F)

    // Accents
    static let aigua = Color.dinamic(clar: 0x3AA6A0, fosc: 0x5CC4BD)
    static let blau = Color.dinamic(clar: 0x4A7BB0, fosc: 0x7AA5D6)
    static let verd = Color.dinamic(clar: 0x6FA35E, fosc: 0x8DC27B)
    static let groc = Color.dinamic(clar: 0xE2AE3A, fosc: 0xF2CB66)
    static let taronja = Color.dinamic(clar: 0xE58B4B, fosc: 0xF0A066)
    static let cafe = Color.dinamic(clar: 0x9C6B48, fosc: 0xC08D67)

    /// Només per a la secció de metges. Ací sí: ALERTA.
    static let alerta = Color.dinamic(clar: 0xD8483B, fosc: 0xF06A5C)
    static let alertaFons = Color.dinamic(clar: 0xFBE9E4, fosc: 0x3A2320)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    static func dinamic(clar: UInt32, fosc: UInt32) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { traits in
            UIColor.desde(hex: traits.userInterfaceStyle == .dark ? fosc : clar)
        })
        #elseif canImport(AppKit)
        return Color(NSColor(name: nil) { aparenca in
            let esFosc = aparenca.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor.desde(hex: esFosc ? fosc : clar)
        })
        #else
        return Color(hex: clar)
        #endif
    }
}

#if canImport(UIKit)
extension UIColor {
    static func desde(hex: UInt32) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}
#elseif canImport(AppKit)
extension NSColor {
    static func desde(hex: UInt32) -> NSColor {
        NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}
#endif

/// Format d'aigua: "1,5 L" o "750 ml".
enum FormatAigua {
    static func text(_ ml: Int) -> String {
        if ml >= 1000 {
            let litres = Double(ml) / 1000
            let f = NumberFormatter()
            f.locale = Locale(identifier: "ca_ES")
            f.maximumFractionDigits = 2
            f.minimumFractionDigits = 0
            return "\(f.string(from: NSNumber(value: litres)) ?? "\(litres)") L"
        }
        return "\(ml) ml"
    }

    static func ampolles(_ ml: Int, ampolla: Int) -> String {
        guard ampolla > 0 else { return "" }
        let n = Double(ml) / Double(ampolla)
        let f = NumberFormatter()
        f.locale = Locale(identifier: "ca_ES")
        f.maximumFractionDigits = 1
        let text = f.string(from: NSNumber(value: n)) ?? "\(n)"
        return n == 1 ? "1 botella" : "\(text) botelles"
    }
}
