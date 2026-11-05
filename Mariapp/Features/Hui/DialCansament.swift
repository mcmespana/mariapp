import SwiftUI

/// El "cansòmetre": dial semicircular de plastilina. S'arrossega amb el dit d'esquerra (0) a dreta (escala).
struct DialCansament: View {
    @Binding var valor: Double
    let escala: Int

    private let gruix: CGFloat = 34

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let radi = min(w / 2, geo.size.height) - gruix / 2 - 6
            let centre = CGPoint(x: w / 2, y: geo.size.height - gruix / 2 - 6)
            let frac = min(max(valor / Double(max(escala, 1)), 0), 1)
            let colorActual = EscalaCansament.color(Int(valor), escala: escala)

            ZStack {
                // Solc de plastilina
                ArcDial(fraccio: 1, centre: centre, radi: radi)
                    .stroke(
                        Paleta.paperFosc.shadow(.inner(color: Color.black.opacity(0.22), radius: 4, x: 2, y: 3)),
                        style: StrokeStyle(lineWidth: gruix, lineCap: .round)
                    )
                // Part plena, de verd a taronja
                ArcDial(fraccio: frac, centre: centre, radi: radi)
                    .stroke(
                        LinearGradient(colors: [Paleta.verd, Paleta.groc, Paleta.taronja], startPoint: .leading, endPoint: .trailing)
                            .shadow(.inner(color: Color.white.opacity(0.55), radius: 3, x: 1, y: 2)),
                        style: StrokeStyle(lineWidth: gruix - 8, lineCap: .round)
                    )
                // Marques cada 10%
                ForEach(0...10, id: \.self) { i in
                    let a = Double.pi * Double(i) / 10
                    let r = radi - gruix / 2 - 10
                    Circle()
                        .fill(Paleta.tintaSuau.opacity(i % 5 == 0 ? 0.6 : 0.25))
                        .frame(width: i % 5 == 0 ? 6 : 4)
                        .position(x: centre.x - r * cos(a), y: centre.y - r * sin(a))
                }
                // Etiquetes dels extrems
                Text("0").font(.system(.caption, design: .rounded).bold()).foregroundStyle(Paleta.tintaSuau)
                    .position(x: centre.x - radi, y: centre.y + gruix / 2 + 4)
                Text("\(escala)").font(.system(.caption, design: .rounded).bold()).foregroundStyle(Paleta.tintaSuau)
                    .position(x: centre.x + radi, y: centre.y + gruix / 2 + 4)
                // Pom: bola de plastilina
                BolaClay(color: colorActual, mida: 50)
                    .overlay {
                        Circle().fill(Color.white.opacity(0.9)).frame(width: 10).offset(x: -6, y: -7)
                    }
                    .position(x: centre.x - radi * cos(Double.pi * frac), y: centre.y - radi * sin(Double.pi * frac))
                    .animation(Clay.molla, value: colorActual)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let dx = g.location.x - centre.x
                        let dy = max(centre.y - g.location.y, 0)
                        let angle = atan2(dy, dx) // 0 = dreta, π = esquerra
                        let f = 1 - angle / Double.pi
                        let pas = escala >= 100 ? Double(escala) / 100 : 1
                        valor = min(max((f * Double(escala) / pas).rounded() * pas, 0), Double(escala))
                    }
            )
        }
        .accessibilityElement()
        .accessibilityLabel("Cansament")
        .accessibilityValue("\(Int(valor)) de \(escala)")
        .accessibilityAdjustableAction { direccio in
            let pas = Double(max(escala / 20, 1))
            switch direccio {
            case .increment: valor = min(valor + pas, Double(escala))
            case .decrement: valor = max(valor - pas, 0)
            @unknown default: break
            }
        }
    }
}

/// Arc semicircular (d'esquerra a dreta per dalt) fins a una fracció.
struct ArcDial: Shape {
    var fraccio: Double
    let centre: CGPoint
    let radi: CGFloat

    var animatableData: Double {
        get { fraccio }
        set { fraccio = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: centre, radius: radi,
                 startAngle: .degrees(180), endAngle: .degrees(180 + 180 * max(fraccio, 0.0001)),
                 clockwise: false)
        return p
    }
}

#Preview {
    @Previewable @State var v: Double = 640
    DialCansament(valor: $v, escala: 1000)
        .frame(height: 200)
        .padding(30)
        .background(FonsAmbTaques())
}
