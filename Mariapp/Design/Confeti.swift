import SwiftUI

/// Pluja de confeti de colors (sense roig ni rosa). Es mostra uns segons i s'apaga sola.
struct Confeti: View {
    private struct Trosset: Identifiable {
        let id = UUID()
        let x = CGFloat.random(in: 0...1)
        let mida = CGFloat.random(in: 7...14)
        let retard = Double.random(in: 0...0.5)
        let durada = Double.random(in: 1.4...2.4)
        let gir = Double.random(in: -540...540)
        let color = [Paleta.aigua, Paleta.blau, Paleta.verd, Paleta.groc, Paleta.taronja, Paleta.cafe].randomElement()!
        let rodo = Bool.random()
    }

    @State private var trossets: [Trosset] = (0..<46).map { _ in Trosset() }
    @State private var cau = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(trossets) { t in
                    Group {
                        if t.rodo {
                            Circle().fill(t.color)
                        } else {
                            RoundedRectangle(cornerRadius: 2, style: .continuous).fill(t.color)
                        }
                    }
                    .frame(width: t.mida, height: t.mida * (t.rodo ? 1 : 0.6))
                    .rotationEffect(.degrees(cau ? t.gir : 0))
                    .position(x: t.x * geo.size.width, y: cau ? geo.size.height + 30 : -30)
                    .opacity(cau ? 0.9 : 1)
                    .animation(.easeIn(duration: t.durada).delay(t.retard), value: cau)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { cau = true }
    }
}
