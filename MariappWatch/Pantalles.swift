import SwiftUI
import WatchKit

// MARK: - Aigua

struct AiguaPantalla: View {
    @Environment(MagatzemRellotge.self) private var magatzem

    var body: some View {
        let h = magatzem.estat.hui
        VStack(spacing: 8) {
            ZStack {
                Circle().stroke(Paleta.aigua.opacity(0.22), lineWidth: 11)
                Circle()
                    .trim(from: 0, to: h.progresAigua)
                    .stroke(Paleta.aigua.gradient, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.smooth, value: h.progresAigua)
                VStack(spacing: 0) {
                    Text(FormatAigua.text(h.aiguaMl))
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.7)
                    Text("de \(FormatAigua.text(h.objectiuMl))")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(Paleta.tintaSuau)
                }
            }
            .frame(width: 104, height: 104)

            HStack(spacing: 8) {
                Button { suma(h.ampollaMl / 2) } label: { Text("+½") }
                Button { suma(h.ampollaMl) } label: { Label("1", systemImage: "waterbottle.fill") }
            }
            .buttonStyle(.borderedProminent)
            .tint(Paleta.aigua)
            .font(.system(.footnote, design: .rounded).weight(.bold))
        }
        .navigationTitle("Aigua")
    }

    private func suma(_ ml: Int) {
        let abans = magatzem.estat.hui
        magatzem.envia(.aigua(ml: ml))
        let arriba = abans.aiguaMl < abans.objectiuMl && abans.aiguaMl + ml >= abans.objectiuMl
        WKInterfaceDevice.current().play(arriba ? .success : .click)
    }
}

// MARK: - Cansòmetre

struct CansamentPantalla: View {
    @Environment(MagatzemRellotge.self) private var magatzem
    @State private var valor: Double = 500
    @State private var apuntat = 0

    var body: some View {
        let escala = magatzem.estat.escalaCansament
        let v = Int(valor)
        VStack(spacing: 2) {
            Text(EscalaRellotge.emoji(v, escala: escala))
                .font(.system(size: 34))
                .contentTransition(.opacity)
            Text("\(v)")
                .font(.system(size: 46, weight: .heavy, design: .rounded))
                .foregroundStyle(EscalaRellotge.color(v, escala: escala))
                .contentTransition(.numericText(value: valor))
                .monospacedDigit()
            Text(magatzem.estat.hui.cansament.map { "Hui: \($0)" } ?? "Gira la corona")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(Paleta.tintaSuau)
            Button {
                magatzem.envia(.cansament(valor: v))
                apuntat += 1
                WKInterfaceDevice.current().play(.success)
            } label: {
                Text("Apuntar").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Paleta.blau)
            .font(.system(.footnote, design: .rounded).weight(.bold))
            .padding(.top, 4)
        }
        .focusable()
        .digitalCrownRotation($valor, from: 0, through: Double(escala), by: 10, sensitivity: .medium, isHapticFeedbackEnabled: true)
        .onAppear { valor = Double(magatzem.estat.hui.cansament ?? escala / 2) }
        .navigationTitle("Cansament")
    }
}

// MARK: - Ràpids

struct RapidsPantalla: View {
    @Environment(MagatzemRellotge.self) private var magatzem

    var body: some View {
        let h = magatzem.estat.hui
        VStack(spacing: 8) {
            Button {
                magatzem.envia(.cafe(quantitat: 1))
                WKInterfaceDevice.current().play(.click)
            } label: {
                HStack {
                    Text("☕️ Café")
                    Spacer()
                    Text("\(h.cafes)").contentTransition(.numericText(value: Double(h.cafes)))
                }
            }
            .tint(Paleta.cafe)

            Button {
                magatzem.envia(.queixa)
                WKInterfaceDevice.current().play(.click)
            } label: {
                HStack {
                    Text("😤 Queixa")
                    Spacer()
                    Text("\(h.queixes)").contentTransition(.numericText(value: Double(h.queixes)))
                }
            }
            .tint(Paleta.taronja)
        }
        .buttonStyle(.borderedProminent)
        .font(.system(.body, design: .rounded).weight(.bold))
        .animation(.smooth, value: h.cafes + h.queixes)
        .navigationTitle("Ràpids")
    }
}

// MARK: - Hui

struct HuiPantalla: View {
    @Environment(MagatzemRellotge.self) private var magatzem

    var body: some View {
        let estat = magatzem.estat
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if let cita = estat.cita, cita.data > Date() {
                    let avui = Calendar.current.isDateInToday(cita.data)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PRÒXIMA CITA")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(Paleta.alerta)
                        Text("\(cita.emoji) \(cita.titol)")
                            .font(.system(.headline, design: .serif))
                        if avui {
                            Text("ÉS HUI! \(cita.data.formatted(date: .omitted, time: .shortened))")
                                .font(.system(.subheadline, design: .rounded).weight(.black))
                                .foregroundStyle(Paleta.alerta)
                        } else {
                            Text(cita.data, style: .relative)
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(Paleta.alerta)
                        }
                    }
                } else {
                    Text("Cap cita pròxima 🎉")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(Paleta.tintaSuau)
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("MENÚ D'HUI")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Paleta.verd)
                    if estat.menuAvui?.dinar != nil || estat.menuAvui?.sopar != nil {
                        if let d = estat.menuAvui?.dinar { Text("☀️ \(d)") }
                        if let s = estat.menuAvui?.sopar { Text("🌙 \(s)") }
                    } else {
                        Text("Sense posar")
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                }
                .font(.system(.footnote, design: .rounded))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Hui")
    }
}
