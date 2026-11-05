import SwiftUI

/// Reparteix els fills en files i els envolta quan no caben (per a xips, etiquetes…).
struct FlowLayout: Layout {
    var espai: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let ample = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var fila: CGFloat = 0
        var maxX: CGFloat = 0
        for s in subviews {
            let m = s.sizeThatFits(.unspecified)
            if x + m.width > ample, x > 0 {
                x = 0
                y += fila + espai
                fila = 0
            }
            x += m.width + espai
            fila = max(fila, m.height)
            maxX = max(maxX, x - espai)
        }
        return CGSize(width: maxX, height: y + fila)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var fila: CGFloat = 0
        for s in subviews {
            let m = s.sizeThatFits(.unspecified)
            if x + m.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += fila + espai
                fila = 0
            }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(m))
            x += m.width + espai
            fila = max(fila, m.height)
        }
    }
}

/// Xip tocable (filtres, etiquetes seleccionables).
struct XipBoto: View {
    let text: String
    var color: Color = Paleta.tintaSuau
    var seleccionat: Bool = false
    let accio: () -> Void

    var body: some View {
        Button(action: accio) {
            Xip(text: text, color: color, seleccionat: seleccionat)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: seleccionat)
        .animation(Clay.molla, value: seleccionat)
    }
}
