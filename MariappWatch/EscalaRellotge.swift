import SwiftUI

/// Els mateixos 11 emojis que `EscalaCansament` de l'iPhone.
enum EscalaRellotge {
    static let emojis = ["🤩", "😄", "😊", "🙂", "😌", "😐", "🥱", "😮‍💨", "😩", "😵‍💫", "🧟‍♀️"]

    static func emoji(_ valor: Int, escala: Int) -> String {
        guard escala > 0 else { return "🙂" }
        let i = Int((Double(valor) / Double(escala) * 10).rounded())
        return emojis[max(0, min(10, i))]
    }

    static func color(_ valor: Int, escala: Int) -> Color {
        let r = Double(valor) / Double(max(escala, 1))
        switch r {
        case ..<0.35: return Paleta.verd
        case ..<0.7: return Paleta.groc
        default: return Paleta.taronja
        }
    }
}
