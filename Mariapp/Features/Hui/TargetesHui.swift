import SwiftUI

// MARK: - Aigua

struct TargetaAigua: View {
    @Environment(DataStore.self) private var store
    let dia: Dia
    @State private var celebra = 0

    var body: some View {
        let cfg = store.config
        let progres = cfg.objectiuMl > 0 ? min(Double(dia.aiguaMl) / Double(cfg.objectiuMl), 1) : 0
        Targeta(tint: Paleta.aigua) {
            CapcaleraTargeta(icona: "drop.fill", titol: "Aigua", color: Paleta.aigua) {
                if dia.aiguaMl > 0 {
                    Menu {
                        Button("Desfer ¼ de botella", systemImage: "arrow.uturn.backward") { suma(-cfg.ampollaMl / 4) }
                        Button("Desfer ½ botella", systemImage: "arrow.uturn.backward") { suma(-cfg.ampollaMl / 2) }
                        Button("Desfer 1 botella", systemImage: "arrow.uturn.backward") { suma(-cfg.ampollaMl) }
                    } label: {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                }
            }
            HStack(alignment: .center, spacing: 20) {
                Botella(progres: progres)
                    .frame(width: 78, height: 140)
                VStack(alignment: .leading, spacing: 6) {
                    Text(FormatAigua.text(dia.aiguaMl))
                        .font(.numeroGran)
                        .foregroundStyle(Paleta.tinta)
                        .contentTransition(.numericText())
                    Text("de \(FormatAigua.text(cfg.objectiuMl)) · \(FormatAigua.ampolles(dia.aiguaMl, ampolla: cfg.ampollaMl))")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(Paleta.tintaSuau)
                    Text(missatge(progres: progres, falten: cfg.objectiuMl - dia.aiguaMl))
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(Paleta.aigua)
                }
            }
            HStack(spacing: 8) {
                Button("+ ¼") { suma(cfg.ampollaMl / 4) }
                Button("+ ½") { suma(cfg.ampollaMl / 2) }
                Button("+ 1 botella") { suma(cfg.ampollaMl) }
            }
            .buttonStyle(.suau(Paleta.aigua))
        }
        .sensoryFeedback(.success, trigger: celebra)
    }

    private func suma(_ ml: Int) {
        let nou = max(0, dia.aiguaMl + ml)
        let objectiu = store.config.objectiuMl
        withAnimation(.spring) {
            store.suma(.aiguaMl, nou - dia.aiguaMl)
        }
        if ml > 0 {
            if dia.aiguaMl < objectiu && nou >= objectiu {
                celebra += 1
                Sons.toca(.festa)
            } else {
                Sons.toca(.gota)
            }
        }
    }

    private func missatge(progres: Double, falten: Int) -> String {
        switch progres {
        case 1...: return "Objectiu complit! 🎉"
        case 0.75..<1: return "Quasi! Falten \(FormatAigua.text(falten))"
        case 0.4..<0.75: return "Vas molt bé 🌿"
        case 0.01..<0.4: return "Bon començament 💧"
        default: return "Un glopet per a començar?"
        }
    }
}

// MARK: - Cansament

enum EscalaCansament {
    static let emojis = ["🤩", "😄", "😊", "🙂", "😌", "😐", "🥱", "😮‍💨", "😩", "😵‍💫", "🧟‍♀️"]

    static func emoji(_ valor: Int, escala: Int) -> String {
        guard escala > 0 else { return "🙂" }
        let i = Int((Double(valor) / Double(escala) * 10).rounded())
        return emojis[max(0, min(10, i))]
    }

    static let frases = [
        "Fresca com una lletuga 🥬",
        "Amb les piles noves 🔋",
        "Prou bé, la veritat",
        "Normalet, tirant",
        "A mig gas ⛽️",
        "Cansadeta",
        "Necessite un sofà 🛋️",
        "Mode zombi activat 🧟‍♀️",
        "Feta pols",
        "Feta pols i escampada 🌪️",
        "Desconnectada. Bona nit 🪦",
    ]

    static func text(_ valor: Int, escala: Int) -> String {
        let r = Double(valor) / Double(max(escala, 1))
        return frases[max(0, min(10, Int(r * 10)))]
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

struct TargetaCansament: View {
    @Environment(DataStore.self) private var store
    @Environment(Navegacio.self) private var nav
    let dia: Dia

    var body: some View {
        let escala = store.config.escalaCansament
        Targeta(tint: Paleta.blau) {
            CapcaleraTargeta(icona: "battery.25percent", titol: "Cansament", color: Paleta.blau)
            if let valor = dia.cansament {
                HStack(spacing: 14) {
                    Text(EscalaCansament.emoji(valor, escala: escala))
                        .font(.system(size: 34))
                        .background { BolaClay(color: EscalaCansament.color(valor, escala: escala), mida: 58) }
                        .frame(width: 60, height: 60)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(valor)")
                                .font(.numeroGran)
                                .foregroundStyle(Paleta.tinta)
                                .contentTransition(.numericText(value: Double(valor)))
                            Text("/ \(escala)")
                                .font(.system(.subheadline, design: .rounded).bold())
                                .foregroundStyle(Paleta.tintaSuau)
                        }
                        Text(EscalaCansament.text(valor, escala: escala))
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                    Spacer()
                    Button("Canviar") { nav.mostraCansament = true }
                        .buttonStyle(.suau(Paleta.blau))
                }
                BarraCansament(fraccio: Double(valor) / Double(max(escala, 1)))
            } else {
                Text("Com estàs de cansada hui?")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Paleta.tintaSuau)
                Button {
                    nav.mostraCansament = true
                } label: {
                    Label("Apuntar el cansament", systemImage: "hand.tap.fill")
                }
                .buttonStyle(.suau(Paleta.blau, ple: true))
            }
        }
    }
}

struct TriaCansament: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var tanca
    let dia: Dia
    @State private var valor: Double = 500

    var body: some View {
        let escala = store.config.escalaCansament
        let v = Int(valor)
        let color = EscalaCansament.color(v, escala: escala)
        VStack(spacing: 18) {
            Text("Com estàs de cansada?")
                .font(.titolGran(26))
                .foregroundStyle(Paleta.tinta)
                .padding(.top, 28)
            Text("El cansòmetre oficial, del 0 al \(escala)")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Paleta.tintaSuau)

            ZStack(alignment: .bottom) {
                DialCansament(valor: $valor, escala: escala)
                VStack(spacing: 0) {
                    Text(EscalaCansament.emoji(v, escala: escala))
                        .font(.system(size: 44))
                        .contentTransition(.opacity)
                    Text("\(v)")
                        .font(.system(size: 58, weight: .heavy, design: .rounded))
                        .foregroundStyle(color)
                        .contentTransition(.numericText(value: valor))
                        .monospacedDigit()
                }
                .padding(.bottom, 22)
                .allowsHitTesting(false)
            }
            .frame(height: 230)
            .padding(.horizontal, 20)
            .sensoryFeedback(.selection, trigger: v / max(escala / 20, 1))

            Text(EscalaCansament.text(v, escala: escala))
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(Paleta.tinta)
                .contentTransition(.opacity)
                .animation(Clay.molla, value: EscalaCansament.text(v, escala: escala))

            HStack(spacing: 14) {
                BotoRodo(titol: "Menys", icona: "minus", color: color) { mou(-Double(max(escala / 20, 1)), escala: escala) }
                Text("Arrossega la bola o afina amb els botons")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Paleta.tintaSuau)
                    .multilineTextAlignment(.center)
                BotoRodo(titol: "Més", icona: "plus", color: color) { mou(Double(max(escala / 20, 1)), escala: escala) }
            }
            .padding(.horizontal, 28)

            Button(action: desa) {
                Text("Apuntar \(v)").frame(maxWidth: .infinity)
            }
            .buttonStyle(.suau(Paleta.blau, ple: true))
            .padding(.horizontal, 32)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { FonsAmbTaques() }
        .onAppear { valor = Double(dia.cansament ?? escala / 2) }
    }

    private func mou(_ delta: Double, escala: Int) {
        withAnimation(Clay.molla) {
            valor = min(max(valor + delta, 0), Double(escala))
        }
    }

    private func desa() {
        store.posa(.cansament, Int(valor), dia: dia.id)
        Sons.toca(.campaneta)
        tanca()
    }
}

/// Barreta de plastilina amb el degradat del cansòmetre.
struct BarraCansament: View {
    let fraccio: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Paleta.paperFosc.shadow(.inner(color: Color.black.opacity(0.18), radius: 3, x: 1, y: 2)))
                Capsule()
                    .fill(LinearGradient(colors: [Paleta.verd, Paleta.groc, Paleta.taronja], startPoint: .leading, endPoint: .trailing)
                        .shadow(.inner(color: Color.white.opacity(0.5), radius: 2, x: 1, y: 1)))
                    .frame(width: max(geo.size.width * min(max(fraccio, 0), 1), 14))
            }
        }
        .frame(height: 14)
        .accessibilityHidden(true)
    }
}

// MARK: - Gimnàs

struct TargetaGimnas: View {
    @Environment(DataStore.self) private var store
    let dia: Dia
    @State private var salta = 0

    var body: some View {
        Targeta(tint: Paleta.verd) {
            CapcaleraTargeta(icona: "figure.strengthtraining.traditional", titol: "Gimnàs", color: Paleta.verd) {
                Text(ratxa)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(Paleta.verd)
            }
            Button {
                let nou = !dia.gimnas
                store.posa(.gimnas, nou)
                if nou { salta += 1; Sons.toca(.festa) }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: dia.gimnas ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28))
                        .symbolEffect(.bounce, value: salta)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dia.gimnas ? "Hui sí! 💪" : "Hui has anat al gimnàs?")
                            .font(.system(.headline, design: .rounded))
                        Text(dia.gimnas ? "Apuntat per a les estadístiques" : "Toca quan hi vages")
                            .font(.system(.caption, design: .rounded))
                            .opacity(0.8)
                    }
                    Spacer()
                }
                .padding(14)
                .foregroundStyle(dia.gimnas ? Color.white : Paleta.verd)
                .clay(Paleta.verd, radi: Clay.radiMitja, elevacio: dia.gimnas ? 0.7 : 0.45, ple: dia.gimnas)
                .animation(Clay.mollaJuganera, value: dia.gimnas)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: salta)
        }
    }

    /// Dies de gimnàs aquest mes.
    private var ratxa: String {
        let cal = Calendar.current
        let n = store.dies.items.filter { $0.gimnas && cal.isDate($0.data, equalTo: Date(), toGranularity: .month) }.count
        return n == 0 ? "" : "\(n) aquest mes"
    }
}

// MARK: - Cafés

struct TargetaCafes: View {
    @Environment(DataStore.self) private var store
    let dia: Dia

    var body: some View {
        Targeta(tint: Paleta.cafe) {
            CapcaleraTargeta(icona: "cup.and.saucer.fill", titol: "Cafés", color: Paleta.cafe)
            HStack {
                if dia.cafes == 0 {
                    Text("Cap café encara ☁️")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Paleta.tintaSuau)
                } else {
                    HStack(spacing: 4) {
                        ForEach(0..<min(dia.cafes, 6), id: \.self) { _ in
                            Text("☕️").font(.system(size: 28)).transition(.scale.combined(with: .opacity))
                        }
                        if dia.cafes > 6 {
                            Text("+\(dia.cafes - 6)").font(.system(.headline, design: .rounded)).foregroundStyle(Paleta.cafe)
                        }
                    }
                }
                Spacer()
                BotoRodo(titol: "Un café menys", icona: "minus", color: Paleta.cafe) {
                    if dia.cafes > 0 { withAnimation(.spring) { store.suma(.cafes, -1) } }
                }
                BotoRodo(titol: "Un café més", icona: "plus", color: Paleta.cafe) {
                    withAnimation(.spring) { store.suma(.cafes, 1) }
                    Sons.toca(.cafe)
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: dia.cafes)
        }
    }
}

// MARK: - Dolor d'orina

struct TargetaDolor: View {
    @Environment(DataStore.self) private var store
    let dia: Dia

    struct Opcio: Identifiable {
        let valor: Int
        let emoji: String
        let nom: String
        var id: Int { valor }
    }

    static let opcions: [Opcio] = [
        Opcio(valor: 0, emoji: "🌼", nom: "Gens"),
        Opcio(valor: 1, emoji: "🌥️", nom: "Un poquet"),
        Opcio(valor: 2, emoji: "🌧️", nom: "Prou"),
        Opcio(valor: 3, emoji: "⛈️", nom: "Molt"),
    ]

    var body: some View {
        Targeta(tint: Paleta.groc) {
            CapcaleraTargeta(icona: "drop.triangle.fill", titol: "Molèsties d'orina", color: Paleta.groc)
            HStack(spacing: 8) {
                ForEach(Self.opcions) { o in
                    let seleccionat = dia.dolor == o.valor
                    Button {
                        store.posa(.dolor, seleccionat ? nil : o.valor)
                    } label: {
                        VStack(spacing: 4) {
                            Text(o.emoji).font(.system(size: 26))
                            Text(o.nom).font(.system(.caption, design: .rounded).bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(seleccionat ? Color.white : Paleta.tinta)
                        .clay(Paleta.groc, radi: Clay.radiXicotet, elevacio: seleccionat ? 0.6 : 0.3, ple: seleccionat)
                        .animation(Clay.mollaJuganera, value: seleccionat)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(seleccionat ? .isSelected : [])
                }
            }
            .sensoryFeedback(.selection, trigger: dia.dolor)
        }
    }
}

// MARK: - Queixes sobre David

struct TargetaQueixes: View {
    @Environment(DataStore.self) private var store
    let dia: Dia

    var body: some View {
        Targeta(tint: Paleta.taronja) {
            CapcaleraTargeta(icona: "exclamationmark.bubble.fill", titol: "Queixes sobre David", color: Paleta.taronja)
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(dia.queixes)")
                        .font(.numeroGran)
                        .foregroundStyle(Paleta.tinta)
                        .contentTransition(.numericText())
                    Text(frase)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Paleta.tintaSuau)
                }
                Spacer()
                BotoRodo(titol: "Una queixa menys", icona: "minus", color: Paleta.taronja) {
                    if dia.queixes > 0 { withAnimation(.spring) { store.suma(.queixes, -1) } }
                }
                Button {
                    withAnimation(.spring) { store.suma(.queixes, 1) }
                    Sons.toca(.queixa)
                } label: {
                    Text("😤 +1")
                }
                .buttonStyle(.suau(Paleta.taronja, ple: true))
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: dia.queixes)
        }
    }

    private var frase: String {
        switch dia.queixes {
        case 0: return "Hui David és un sol ☀️"
        case 1...2: return "Res greu, coses de parella"
        case 3...5: return "Ai, David, David… 🙄"
        case 6...9: return "David, revisa't 🫠"
        default: return "Cal una reunió urgent 🚨"
        }
    }
}

// MARK: - Nota del dia

struct TargetaNota: View {
    @Environment(DataStore.self) private var store
    let dia: Dia
    @State private var text = ""
    @FocusState private var enfocat: Bool

    var body: some View {
        Targeta {
            CapcaleraTargeta(icona: "pencil.and.scribble", titol: "Nota del dia", color: Paleta.tintaSuau)
            TextField("Com ha anat? Alguna cosa a recordar…", text: $text, axis: .vertical)
                .lineLimit(2...6)
                .font(.system(.body, design: .rounded))
                .focused($enfocat)
                .onSubmit(desa)
                .onChange(of: enfocat) { _, ara in if !ara { desa() } }
        }
        .onAppear { text = dia.nota ?? "" }
        .onChange(of: dia.nota) { _, nova in if !enfocat { text = nova ?? "" } }
    }

    private func desa() {
        let net = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard net != (dia.nota ?? "") else { return }
        store.posa(.nota, net.isEmpty ? nil : net, dia: dia.id)
    }
}
