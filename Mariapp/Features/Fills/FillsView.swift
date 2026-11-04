import SwiftUI

/// Secció "Fills / Filles / Fillis…" (el nom canvia cada dia). De moment, pura màgia i animacions.
struct FillsView: View {
    @State private var bombolles: [Bombolla] = (0..<18).map { _ in Bombolla() }
    @State private var tocs = 0
    @State private var inici = Date()

    private let missatges = [
        "Ací passaran coses boniques. Algun dia. ✨",
        "Espai reservat per a persones xicotetes 🍼",
        "De moment, només hi ha bombolles 🫧",
        "Prohibit entrar sense somriure 😊",
        "Proximament: bolquers, nits sense dormir i molt d'amor 💛",
    ]

    var body: some View {
        ZStack {
            Paleta.fons.ignoresSafeArea()
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSince(inici)
                Canvas { ctx, mida in
                    for b in bombolles {
                        let y = mida.height - CGFloat((t * b.velocitat + b.desfase).truncatingRemainder(dividingBy: 1.2)) * mida.height
                        let x = b.x * mida.width + CGFloat(sin(t * b.oscil + b.desfase * 6)) * 18
                        let rect = CGRect(x: x - b.mida / 2, y: y - b.mida / 2, width: b.mida, height: b.mida)
                        ctx.fill(Path(ellipseIn: rect), with: .color(b.color.opacity(0.28)))
                        if b.emoji != nil {
                            ctx.draw(Text(b.emoji!).font(.system(size: b.mida * 0.5)), at: CGPoint(x: x, y: y))
                        }
                    }
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Text(NomFills.dHui)
                    .font(.titolGran(44))
                    .foregroundStyle(Paleta.tinta)
                    .contentTransition(.numericText())
                Text(missatges[tocs % missatges.count])
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(Paleta.tintaSuau)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .contentTransition(.opacity)
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        tocs += 1
                        bombolles.append(contentsOf: (0..<6).map { _ in Bombolla(ambEmoji: true) })
                        if bombolles.count > 60 { bombolles.removeFirst(6) }
                    }
                    Sons.toca(.festa)
                } label: {
                    Label("Més màgia", systemImage: "wand.and.stars")
                }
                .buttonStyle(.suau(Paleta.groc, ple: true))
                .sensoryFeedback(.success, trigger: tocs)
            }
        }
        .navigationTitle(NomFills.dHui)
    }
}

private struct Bombolla: Identifiable {
    let id = UUID()
    let x = CGFloat.random(in: 0.05...0.95)
    let mida = CGFloat.random(in: 24...78)
    let velocitat = Double.random(in: 0.04...0.12)
    let oscil = Double.random(in: 0.5...1.6)
    let desfase = Double.random(in: 0...1.2)
    let color = [Paleta.aigua, Paleta.groc, Paleta.verd, Paleta.blau, Paleta.taronja].randomElement()!
    var emoji: String?

    init(ambEmoji: Bool = false) {
        if ambEmoji || Bool.random() && Bool.random() {
            emoji = ["🍼", "🧸", "👶", "🐣", "🌈", "⭐️", "🦆", "🎈"].randomElement()
        }
    }
}
