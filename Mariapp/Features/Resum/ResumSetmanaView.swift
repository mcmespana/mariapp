import Charts
import SwiftUI

/// "Com t'ha anat la setmana": targetes amb l'aigua, el gimnàs, el cansament i els petits comptes,
/// comparades amb la setmana anterior. Es pot veure cada setmana amb les fletxes.
struct ResumSetmanaView: View {
    @Environment(DataStore.self) private var store
    @Environment(Navegacio.self) private var nav
    @Environment(\.dismiss) private var tanca

    @State private var inici = ResumSetmanal.setmanaPerDefecte()
    @State private var celebra = 0
    @State private var textIA: String?
    @State private var errorIA: String?
    @State private var carregantIA = false

    private var escala: Int { store.config.escalaCansament }
    private var objectiu: Int { store.config.objectiuMl }

    var body: some View {
        let dies = store.dies.items
        let resum = ResumSetmanal.calcula(dies: dies, setmana: inici, objectiuMl: objectiu)
        let anterior = ResumSetmanal.calcula(dies: dies, setmana: Setmana.mou(inici, setmanes: -1), objectiuMl: objectiu)
        let comparativa = ResumSetmanal.comparativa(actual: resum, anterior: anterior, escala: escala)

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                selector
                if !resum.teDades {
                    Targeta(tint: Paleta.aigua) {
                        Text("Esta setmana no hi ha res apuntat 🌱")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16, alignment: .top)], spacing: 16) {
                    targetaAigua(resum)
                    targetaGimnas(resum)
                    if resum.cansamentMitja != nil { targetaCansament(resum) }
                    petitsComptes(resum)
                    if !comparativa.isEmpty { targetaComparativa(comparativa) }
                    targetaIA(resum, comparativa: comparativa)
                    targetaSetmanaQueVe
                }
            }
            .padding(16)
            .ampleMaxim(1100)
        }
        .fonsMariapp()
        .navigationTitle("Resum setmanal")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Fet") { tanca() }
            }
        }
        .sensoryFeedback(.success, trigger: celebra)
        .onAppear { festeja(resum) }
        .onChange(of: inici) { _, _ in
            textIA = nil
            errorIA = nil
        }
        #if os(macOS)
        .frame(minWidth: 560, minHeight: 700)
        #endif
    }

    // MARK: Selector de setmana

    private var selector: some View {
        let actual = Setmana.inici(de: Date())
        return HStack(spacing: 12) {
            BotoRodo(titol: "Setmana anterior", icona: "chevron.left", color: Paleta.aigua) { canvia(-1) }
            VStack(spacing: 2) {
                Text(Setmana.titol(inici))
                    .font(.titolGran(26))
                    .foregroundStyle(Paleta.tinta)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(etiquetaSetmana)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(Paleta.tintaSuau)
            }
            .frame(maxWidth: .infinity)
            BotoRodo(titol: "Setmana següent", icona: "chevron.right", color: Paleta.aigua) { canvia(1) }
                .disabled(inici >= actual)
                .opacity(inici >= actual ? 0.4 : 1)
        }
        .padding(.top, 8)
    }

    private var etiquetaSetmana: String {
        let actual = Setmana.inici(de: Date())
        let n = Setmana.numeroSetmana(inici)
        if inici == actual { return "Setmana \(n) · esta setmana" }
        if inici == Setmana.mou(actual, setmanes: -1) { return "Setmana \(n) · la setmana passada" }
        return "Setmana \(n)"
    }

    private func canvia(_ setmanes: Int) {
        let nova = Setmana.mou(inici, setmanes: setmanes)
        guard nova <= Setmana.inici(de: Date()) else { return }
        withAnimation(Clay.molla) { inici = nova }
    }

    private func festeja(_ resum: ResumSetmana) {
        if resum.diesObjectiuAigua >= 5 {
            celebra += 1
            Sons.toca(.festa)
        }
    }

    // MARK: Targetes

    private func targetaAigua(_ r: ResumSetmana) -> some View {
        Targeta(tint: Paleta.aigua) {
            CapcaleraTargeta(icona: "drop.fill", titol: "Aigua", color: Paleta.aigua) {
                Text("\(r.diesObjectiuAigua) de 7 amb objectiu")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(Paleta.aigua)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(FormatAigua.text(r.aiguaTotalMl))
                    .font(.numeroGran)
                    .foregroundStyle(Paleta.tinta)
                    .contentTransition(.numericText(value: Double(r.aiguaTotalMl)))
                Text("en total")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Paleta.tintaSuau)
            }
            if let millor = r.millorDiaAigua {
                Text("🏆 El millor dia: \(millor.nomDia) amb \(FormatAigua.text(millor.valor))")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(Paleta.tinta)
            }
            Chart {
                ForEach(r.dies) { d in
                    BarMark(x: .value("Dia", d.nom), y: .value("ml", d.aiguaMl))
                        .foregroundStyle((d.aiguaMl >= objectiu ? Paleta.aigua : Paleta.aigua.opacity(0.5)).gradient)
                        .cornerRadius(6)
                }
                RuleMark(y: .value("Objectiu", objectiu))
                    .foregroundStyle(Paleta.aigua.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("objectiu").font(.caption2).foregroundStyle(Paleta.aigua)
                    }
            }
            .frame(height: 160)
        }
    }

    private func targetaGimnas(_ r: ResumSetmana) -> some View {
        Targeta(tint: Paleta.verd) {
            CapcaleraTargeta(icona: "figure.strengthtraining.traditional", titol: "Gimnàs", color: Paleta.verd) {
                Text(r.diesGimnas == 0 ? "Cap dia" : ResumSetmanal.dies(r.diesGimnas))
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(Paleta.verd)
            }
            HStack(spacing: 0) {
                ForEach(r.dies) { d in
                    VStack(spacing: 8) {
                        Text(d.inicial)
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(Paleta.tintaSuau)
                        if d.gimnas {
                            BolaClay(color: Paleta.verd, mida: 30)
                                .overlay { Image(systemName: "checkmark").font(.caption.weight(.heavy)).foregroundStyle(.white) }
                        } else {
                            Circle()
                                .fill(Paleta.verd.opacity(0.14))
                                .frame(width: 30, height: 30)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(Analisi.nomsDiesLlargs[d.numero - 1]): \(d.gimnas ? "gimnàs" : "sense gimnàs")")
                }
            }
            .animation(Clay.molla, value: r.diesGimnas)
        }
    }

    private func targetaCansament(_ r: ResumSetmana) -> some View {
        let mitja = Int((r.cansamentMitja ?? 0).rounded())
        return Targeta(tint: Paleta.blau) {
            CapcaleraTargeta(icona: "battery.25percent", titol: "Cansament", color: Paleta.blau)
            HStack(spacing: 14) {
                Text(EscalaCansament.emoji(mitja, escala: escala))
                    .font(.system(size: 34))
                    .background { BolaClay(color: EscalaCansament.color(mitja, escala: escala), mida: 58) }
                    .frame(width: 60, height: 60)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(mitja)")
                            .font(.numeroGran)
                            .foregroundStyle(Paleta.tinta)
                            .contentTransition(.numericText(value: Double(mitja)))
                        Text("de mitjana")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                    Text(EscalaCansament.text(mitja, escala: escala))
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Paleta.tintaSuau)
                }
            }
            BarraCansament(fraccio: Double(mitja) / Double(max(escala, 1)))
            if let pitjor = r.diaMesCansat, let millor = r.diaMenysCansat {
                VStack(alignment: .leading, spacing: 4) {
                    Text("😮‍💨 El més dur: \(pitjor.nomDia) (\(pitjor.valor))")
                    Text("🌿 El més lleuger: \(millor.nomDia) (\(millor.valor))")
                }
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Paleta.tinta)
            }
        }
    }

    private func petitsComptes(_ r: ResumSetmana) -> some View {
        HStack(alignment: .top, spacing: 12) {
            miniTargeta(emoji: "☕️", valor: r.cafes, text: r.cafes == 1 ? "café" : "cafés", color: Paleta.cafe)
            miniTargeta(emoji: "😤", valor: r.queixes, text: r.queixes == 1 ? "queixa" : "queixes", color: Paleta.taronja)
            miniTargeta(emoji: "🌦️", valor: r.diesMolesties, text: r.diesMolesties == 1 ? "dia amb molèsties" : "dies amb molèsties", color: Paleta.groc)
        }
    }

    private func miniTargeta(emoji: String, valor: Int, text: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(emoji).font(.system(size: 26))
            Text("\(valor)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Paleta.tinta)
                .contentTransition(.numericText(value: Double(valor)))
            Text(text)
                .font(.system(.caption2, design: .rounded).weight(.semibold))
                .foregroundStyle(Paleta.tintaSuau)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .clay(color, radi: Clay.radiMitja, elevacio: 0.55)
        .accessibilityElement(children: .combine)
    }

    private func targetaComparativa(_ frases: [String]) -> some View {
        Targeta(tint: Paleta.groc) {
            CapcaleraTargeta(icona: "arrow.left.arrow.right", titol: "Comparat amb la setmana passada", color: Paleta.groc)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(frases, id: \.self) { frase in
                    Text(frase)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(Paleta.tinta)
                }
            }
        }
    }

    private func targetaIA(_ r: ResumSetmana, comparativa: [String]) -> some View {
        Targeta(tint: Paleta.groc) {
            CapcaleraTargeta(icona: "sparkles", titol: "Mirada amable", color: Paleta.groc)
            BotoIA(titol: "✨ Un comentari per a la setmana", carregant: carregantIA) {
                comenta(r, comparativa: comparativa)
            }
            ResultatIA(text: textIA, error: errorIA, carregant: carregantIA)
        }
    }

    private func comenta(_ r: ResumSetmana, comparativa: [String]) {
        carregantIA = true
        textIA = nil
        errorIA = nil
        let dades = ResumSetmanal.resumPerIA(r, comparativa: comparativa, escala: escala, objectiuMl: objectiu)
        let sistema = ServeiIA.sistemaBase + """

        Ara fas d'amiga atenta: comenta la setmana de la Maria en 3 o 4 frases cariñoses (no més), destacant una cosa bonica i, si cal, un xicotet suggeriment pràctic.
        Mai consells mèdics ni res alarmista; si alguna cosa pareix preocupant, suggerix amb dolçor comentar-ho amb la metgessa.
        """
        Task {
            do {
                textIA = try await ServeiIA.pregunta("Estes són les dades de la meua setmana (agregades):\n\(dades)", sistema: sistema, maxTokens: 500)
            } catch {
                errorIA = error.missatgeIA
            }
            carregantIA = false
        }
    }

    private var targetaSetmanaQueVe: some View {
        let proximDilluns = Setmana.mou(Setmana.inici(de: Date()), setmanes: 1)
        let cita = ServeiCites.properaCita(store.cites.items)
        let menu = store.menus[MenuSetmana.id(per: proximDilluns)]
        func text(_ apat: Apat) -> String? {
            guard let e = menu?.entrada(dia: 1, apat: apat) else { return nil }
            if let id = e.platId, let p = store.plats[id] { return "\(p.emoji) \(p.nom)" }
            return e.text
        }
        return Targeta(tint: Paleta.verd) {
            CapcaleraTargeta(icona: "forward.fill", titol: "La setmana que ve", color: Paleta.verd)
            if let cita, let data = cita.data {
                let emoji = ServeiCites.categoria(cita)?.emoji ?? "🏥"
                Label("\(emoji) \(cita.titol) · \(Dates.llarga(data)) a les \(Dates.hora(data))", systemImage: "cross.case.fill")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(Paleta.tinta)
            } else {
                Text("Cap cita a la vista 🎉")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Paleta.tintaSuau)
            }
            if text(.dinar) != nil || text(.sopar) != nil {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dilluns")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(Paleta.tintaSuau)
                    if let d = text(.dinar) { Text("☀️ \(d)") }
                    if let s = text(.sopar) { Text("🌙 \(s)") }
                }
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Paleta.tinta)
            } else {
                Text("El menú de dilluns encara està buit 🍲")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Paleta.tintaSuau)
            }
            Button("Anar al menú") {
                tanca()
                nav.seccio = .menu
            }
            .buttonStyle(.suau(Paleta.verd))
        }
    }
}

/// A Hui: els diumenges a partir de les 18:00 i els dilluns, un convit a mirar com ha anat la setmana.
struct TargetaResum: View {
    @Environment(Navegacio.self) private var nav

    var body: some View {
        TimelineView(.everyMinute) { context in
            if toca(context.date) {
                Button {
                    nav.mostraResum = true
                } label: {
                    Targeta(tint: Paleta.aigua) {
                        CapcaleraTargeta(icona: "chart.bar.doc.horizontal.fill", titol: "Resum setmanal", color: Paleta.aigua) {
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(Paleta.tintaSuau)
                        }
                        Text("Mira el resum de la setmana ✨")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Paleta.tinta)
                        Text("Aigua, gimnàs, cansament i com ha anat tot comparat amb l'anterior.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toca(_ ara: Date) -> Bool {
        let dia = Setmana.numeroDia(ara)
        let hora = Calendar.current.component(.hour, from: ara)
        return dia == 1 || (dia == 7 && hora >= 18)
    }
}
