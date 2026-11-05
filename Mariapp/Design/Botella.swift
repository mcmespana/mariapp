import SwiftUI

/// Botella amb aigua que fa onades. El nivell puja amb animació quan beus.
struct Botella: View {
    var progres: Double
    var color: Color = Paleta.aigua
    @Environment(\.accessibilityReduceMotion) private var reduirMoviment

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduirMoviment)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                FormaBotella().fill(
                    Paleta.paperFosc.shadow(.inner(color: color.opacity(0.25), radius: 6, x: -3, y: -4))
                )
                Onada(nivell: progres, fase: t * 1.8, amplitud: 4).fill(color.opacity(0.35))
                Onada(nivell: progres, fase: t * 2.5 + 1.3, amplitud: 3).fill(color.opacity(0.85))
                // Reflex de vidre
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 6)
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
            }
            .clipShape(FormaBotella())
            .overlay {
                // Vores de plastilina: llum dalt, ombra baix.
                FormaBotella().stroke(
                    LinearGradient(colors: [Color.white.opacity(0.9), color.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 3
                )
            }
            .shadow(color: color.opacity(0.35), radius: 12, x: 0, y: 8)
        }
        .animation(.spring(response: 0.9, dampingFraction: 0.7), value: progres)
        .accessibilityElement()
        .accessibilityLabel("Botella d'aigua al \(Int(progres * 100)) per cent")
    }
}

struct FormaBotella: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        let collW = w * 0.44, collH = h * 0.15, espatla = h * 0.13, radi = min(w, h) * 0.16
        let x0 = r.minX + (w - collW) / 2
        let x1 = x0 + collW
        var p = Path()
        p.move(to: CGPoint(x: x0 + 4, y: r.minY))
        p.addLine(to: CGPoint(x: x1 - 4, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: x1, y: r.minY + 4), control: CGPoint(x: x1, y: r.minY))
        p.addLine(to: CGPoint(x: x1, y: r.minY + collH))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + collH + espatla), control: CGPoint(x: r.maxX, y: r.minY + collH))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - radi))
        p.addQuadCurve(to: CGPoint(x: r.maxX - radi, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + radi, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - radi), control: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + collH + espatla))
        p.addQuadCurve(to: CGPoint(x: x0, y: r.minY + collH), control: CGPoint(x: r.minX, y: r.minY + collH))
        p.addLine(to: CGPoint(x: x0, y: r.minY + 4))
        p.addQuadCurve(to: CGPoint(x: x0 + 4, y: r.minY), control: CGPoint(x: x0, y: r.minY))
        p.closeSubpath()
        return p
    }
}

struct Onada: Shape {
    var nivell: Double
    var fase: Double
    var amplitud: CGFloat

    var animatableData: Double {
        get { nivell }
        set { nivell = newValue }
    }

    func path(in r: CGRect) -> Path {
        let n = max(0, min(nivell, 1))
        let y0 = r.maxY - CGFloat(n) * r.height * 0.92
        let amp = n <= 0.001 ? 0 : amplitud
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: y0))
        let passos = 40
        for i in 0...passos {
            let x = r.minX + r.width * CGFloat(i) / CGFloat(passos)
            let angle = Double(i) / Double(passos) * .pi * 2 + fase
            p.addLine(to: CGPoint(x: x, y: y0 + CGFloat(sin(angle)) * amp))
        }
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    Botella(progres: 0.6).frame(width: 100, height: 170).padding().background(Paleta.fons)
}
