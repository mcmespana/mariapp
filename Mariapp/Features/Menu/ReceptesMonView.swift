import SwiftUI

/// "🌍 Receptes del món": busca a TheMealDB (amb foto), tradueix al valencià amb la IA i guarda com a plat.
/// A la segona pestanya, "Què faig amb el que tinc?" (només IA).
struct ReceptesMonView: View {
    /// Si ve de triar plat per a un forat del menú: guarda i posa-ho allà.
    var alPosarAlMenu: ((Plat) -> Void)? = nil

    enum Mode: String, CaseIterable, Identifiable {
        case mon = "🌍 Del món"
        case queTinc = "🥕 Què tinc?"
        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode = .mon

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Què vols fer?", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                switch mode {
                case .mon: CercaReceptesMon(alPosarAlMenu: posaIAcaba)
                case .queTinc: QueFaigAmbElQueTinc(alPosarAlMenu: posaIAcaba)
                }
            }
            .fonsMariapp()
            .navigationTitle("Receptes del món")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .sensoryFeedback(.selection, trigger: mode)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tanca") { dismiss() }
                }
            }
            .navigationDestination(for: ReceptaExterna.self) { recepta in
                DetallReceptaExterna(inicial: recepta, alPosarAlMenu: posaIAcaba)
            }
        }
        #if os(macOS)
        .frame(minWidth: 560, minHeight: 700)
        #endif
    }

    /// Posa el plat al forat del menú i tanca esta pantalla. nil si no venim de triar plat.
    private var posaIAcaba: ((Plat) -> Void)? {
        guard let alPosarAlMenu else { return nil }
        return { plat in
            alPosarAlMenu(plat)
            dismiss()
        }
    }
}

// MARK: - Cerca

private struct CercaReceptesMon: View {
    var alPosarAlMenu: ((Plat) -> Void)?

    @State private var cerca = ""
    @State private var resultats: [ReceptaExterna] = []
    @State private var titol: String?
    @State private var carregant = false
    @State private var error: String?
    @State private var triada: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                FlowLayout(espai: 8) {
                    XipBoto(text: "Espanyoles 🇪🇸", color: Paleta.verd, seleccionat: triada == "esp") {
                        executa("esp", titol: "Receptes espanyoles 🇪🇸") { try await ServeiReceptes.espanyoles() }
                    }
                    XipBoto(text: "Sorprén-me 🎲", color: Paleta.groc, seleccionat: triada == "random") {
                        executa("random", titol: "Una sorpresa 🎲") {
                            var jaVistes: [ReceptaExterna] = []
                            // Tres de cop, perquè la rejilla quede bonica.
                            for _ in 0..<3 {
                                if let r = try await ServeiReceptes.aleatoria(), !jaVistes.contains(where: { $0.id == r.id }) { jaVistes.append(r) }
                            }
                            return jaVistes
                        }
                    }
                    ForEach(ServeiReceptes.categories) { c in
                        XipBoto(text: c.nom, color: Paleta.verd, seleccionat: triada == c.api) {
                            executa(c.api, titol: c.nom) { try await ServeiReceptes.perCategoria(c.api) }
                        }
                    }
                }

                if carregant {
                    HStack(spacing: 10) {
                        ProgressView().controlSize(.small)
                        Text("Buscant receptes… 🍳")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                } else if let error {
                    Targeta(tint: Paleta.groc) {
                        Text(error)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Paleta.tinta)
                    }
                } else if let titol {
                    Text(resultats.isEmpty ? "Cap recepta per a «\(titol)» 🤔" : titol)
                        .font(.titolSeccio)
                        .foregroundStyle(Paleta.tinta)
                } else {
                    Targeta(tint: Paleta.verd) {
                        Text("Busca un plat («pasta», «pollastre»…) o tria una categoria. Les receptes vénen en anglés i la IA te les passa al valencià ✨")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 14, alignment: .top)], spacing: 14) {
                    ForEach(resultats) { r in
                        NavigationLink(value: r) {
                            TargetaReceptaExterna(recepta: r)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .animation(Clay.molla, value: resultats.map(\.id))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .searchable(text: $cerca, prompt: "Cerca una recepta o un ingredient")
        .onSubmit(of: .search) {
            let text = cerca.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return }
            executa("cerca", titol: text) { try await ServeiReceptes.cercaDelUsuari(text) }
        }
    }

    private func executa(_ clau: String, titol: String, _ feina: @escaping () async throws -> [ReceptaExterna]) {
        triada = clau
        carregant = true
        error = nil
        Task {
            do {
                let r = try await feina()
                withAnimation(Clay.molla) {
                    resultats = r
                    self.titol = titol
                }
            } catch {
                resultats = []
                self.titol = nil
                self.error = error.missatgeIA
            }
            carregant = false
        }
    }
}

struct TargetaReceptaExterna: View {
    let recepta: ReceptaExterna

    var body: some View {
        Targeta(tint: Paleta.verd) {
            FotoPlat(url: recepta.imatge, alcada: 110)
            Text(recepta.nom)
                .font(.titolTargeta)
                .foregroundStyle(Paleta.tinta)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            if let categoria = recepta.categoria ?? recepta.area {
                Xip(text: categoria, color: Paleta.verd)
            }
        }
    }
}

// MARK: - Detall d'una recepta externa

struct DetallReceptaExterna: View {
    var alPosarAlMenu: ((Plat) -> Void)?

    @State private var recepta: ReceptaExterna
    @State private var traduida: ReceptaTraduida?
    @State private var carregantIA = false
    @State private var carregantTM = false
    @State private var errorIA: String?
    @State private var errorDetall: String?

    init(inicial: ReceptaExterna, alPosarAlMenu: ((Plat) -> Void)? = nil) {
        _recepta = State(initialValue: inicial)
        self.alPosarAlMenu = alPosarAlMenu
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                capcalera
                accionsIA
                if let traduida {
                    traduidaVista(traduida)
                } else {
                    originalVista
                }
            }
            .padding(16)
            .ampleMaxim(720)
        }
        .fonsMariapp()
        .navigationTitle(recepta.nom)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await carregaDetallSiCal() }
    }

    // MARK: Peces

    private var capcalera: some View {
        Targeta(tint: Paleta.verd) {
            FotoPlat(url: recepta.imatge, emoji: traduida?.emoji ?? "🍲", alcada: 220)
            Text(traduida?.nom ?? recepta.nom)
                .font(.titolGran(28))
                .foregroundStyle(Paleta.tinta)
            if traduida != nil, recepta.nom != traduida?.nom {
                Text("Original: \(recepta.nom)")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Paleta.tintaSuau)
            }
            FlowLayout(espai: 6) {
                if let c = recepta.categoria { Xip(text: c, color: Paleta.verd) }
                if let a = recepta.area { Xip(text: a, color: Paleta.blau) }
                if traduida?.thermomix == true { Xip(text: "🫕 Thermomix", color: Paleta.cafe, seleccionat: true) }
                ForEach(traduida?.etiquetes.compactMap { EtiquetaPlat(rawValue: $0.lowercased()) } ?? []) { e in
                    Xip(text: "\(e.emoji) \(e.nom)", color: Paleta.verd)
                }
            }
            if recepta.youtube != nil || recepta.font != nil {
                HStack(spacing: 10) {
                    if let y = recepta.youtube {
                        Link(destination: y) { Label("Vídeo", systemImage: "play.rectangle.fill") }
                            .buttonStyle(.suau(Paleta.blau))
                    }
                    if let f = recepta.font {
                        Link(destination: f) { Label("Font", systemImage: "safari") }
                            .buttonStyle(.suau(Paleta.blau))
                    }
                }
            }
        }
    }

    private var accionsIA: some View {
        Targeta(tint: Paleta.groc) {
            CapcaleraTargeta(icona: "sparkles", titol: traduida == nil ? "Passa-la al valencià" : "Una altra versió", color: Paleta.groc)
            BotoIA(titol: "✨ Tradueix-la", carregant: carregantIA) { tradueix(thermomix: false) }
            BotoIA(titol: "🫕 Tradueix i adapta a la Thermomix", carregant: carregantTM) { tradueix(thermomix: true) }
            ResultatIA(text: nil, error: errorIA, carregant: carregantIA || carregantTM)
        }
    }

    @ViewBuilder
    private var originalVista: some View {
        if let errorDetall {
            Targeta(tint: Paleta.groc) {
                Text(errorDetall)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Paleta.tinta)
            }
        }
        if recepta.esResum && errorDetall == nil {
            HStack(spacing: 10) {
                ProgressView().controlSize(.small)
                Text("Carregant la recepta… 🍳")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Paleta.tintaSuau)
            }
        }
        if !recepta.ingredients.isEmpty {
            Targeta(tint: Paleta.verd) {
                CapcaleraTargeta(icona: "basket.fill", titol: "Ingredients (en anglés)", color: Paleta.verd)
                ForEach(Array(recepta.ingredients.enumerated()), id: \.offset) { _, ing in
                    Label(ing.text, systemImage: "circle.fill")
                        .labelStyle(PuntLlista())
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Paleta.tinta)
                }
            }
        }
        if !recepta.paragrafs.isEmpty {
            Targeta(tint: Paleta.groc) {
                CapcaleraTargeta(icona: "book.fill", titol: "Preparació (en anglés)", color: Paleta.groc)
                ForEach(Array(recepta.paragrafs.enumerated()), id: \.offset) { _, par in
                    Text(par)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Paleta.tinta)
                        .textSelection(.enabled)
                }
            }
        }
        if !recepta.esResum {
            Targeta(tint: Paleta.verd) {
                Text("Sense traduir també la pots guardar (en anglés) i traduir-la quan tingues la clau de la IA a Ajustos.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Paleta.tintaSuau)
                GuardaReceptaBotons(titol: "Guardar tal qual", fesPlat: { recepta.comPlatSenseTraduir() }, alPosarAlMenu: alPosarAlMenu)
            }
        }
    }

    private func traduidaVista(_ t: ReceptaTraduida) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if !t.ingredients.isEmpty {
                Targeta(tint: Paleta.verd) {
                    CapcaleraTargeta(icona: "basket.fill", titol: "Ingredients", color: Paleta.verd)
                    ForEach(Array(t.ingredients.enumerated()), id: \.offset) { _, ing in
                        Label(ing, systemImage: "circle.fill")
                            .labelStyle(PuntLlista())
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Paleta.tinta)
                    }
                }
            }
            if !t.passos.isEmpty {
                Targeta(tint: Paleta.groc) {
                    CapcaleraTargeta(icona: "list.number", titol: t.thermomix ? "Passos (Thermomix TM6)" : "Passos", color: Paleta.groc)
                    ForEach(t.passosNumerats, id: \.self) { pas in
                        Text(pas)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Paleta.tinta)
                            .textSelection(.enabled)
                    }
                }
            }
            Targeta(tint: Paleta.verd) {
                GuardaReceptaBotons(titol: "Guardar als meus plats", fesPlat: { t.comPlat(font: recepta) }, alPosarAlMenu: alPosarAlMenu)
                    .id(t)   // una altra traducció = un altre botó (sense l'estat de "ja guardada")
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: Càrrega

    private func carregaDetallSiCal() async {
        guard recepta.esResum else { return }
        do {
            if let complet = try await ServeiReceptes.detall(id: recepta.id) {
                withAnimation(Clay.molla) { recepta = complet }
            } else {
                errorDetall = "No he trobat el detall d'esta recepta 🤷‍♀️"
            }
        } catch {
            errorDetall = error.missatgeIA
        }
    }

    private func tradueix(thermomix: Bool) {
        if thermomix { carregantTM = true } else { carregantIA = true }
        errorIA = nil
        Task {
            // Si encara només tenim el resum, primer el detall.
            await carregaDetallSiCal()
            do {
                let t = try await ServeiReceptes.tradueix(recepta, thermomix: thermomix)
                withAnimation(Clay.molla) { traduida = t }
            } catch {
                errorIA = error.missatgeIA
            }
            carregantIA = false
            carregantTM = false
        }
    }
}

/// Punt petit de llista (en lloc de la icona gran d'un `Label`).
private struct PuntLlista: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            configuration.icon
                .font(.system(size: 5))
                .foregroundStyle(Paleta.verd)
                .offset(y: -3)
            configuration.title
        }
    }
}

// MARK: - Guardar

/// "Guardar als meus plats" (i, si venim del menú, "Guardar i posar al menú"). No duplica si es toca dos voltes.
struct GuardaReceptaBotons: View {
    let titol: String
    let fesPlat: () -> Plat
    var alPosarAlMenu: ((Plat) -> Void)?

    @Environment(DataStore.self) private var store
    @State private var guardat: Plat?
    @State private var salta = 0

    var body: some View {
        VStack(spacing: 10) {
            Button {
                guarda()
            } label: {
                Label(guardat == nil ? titol : "Guardada als teus plats ✅",
                      systemImage: guardat == nil ? "tray.and.arrow.down.fill" : "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.suau(Paleta.verd, ple: guardat == nil))
            .disabled(guardat != nil)

            if let alPosarAlMenu {
                Button {
                    alPosarAlMenu(guarda())
                } label: {
                    Label("Guardar i posar al menú", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.suau(Paleta.verd, ple: true))
            }
        }
        .sensoryFeedback(.success, trigger: salta)
    }

    @discardableResult
    private func guarda() -> Plat {
        if let guardat { return guardat }
        let plat = fesPlat()
        store.plats.desa(plat)
        withAnimation(Clay.mollaJuganera) { guardat = plat }
        salta += 1
        Sons.toca(.festa)
        return plat
    }
}

// MARK: - Què faig amb el que tinc?

private struct QueFaigAmbElQueTinc: View {
    var alPosarAlMenu: ((Plat) -> Void)?

    @State private var ingredients: [String] = []
    @State private var nou = ""
    @State private var thermomix = false
    @State private var propostes: [ReceptaTraduida] = []
    @State private var carregant = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Targeta(tint: Paleta.groc) {
                    CapcaleraTargeta(icona: "refrigerator.fill", titol: "Què tens a casa?", color: Paleta.groc)
                    HStack(spacing: 10) {
                        TextField("Pollastre, cigrons, carabasseta…", text: $nou)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit(afegeix)
                        Button("Afig", action: afegeix)
                            .buttonStyle(.suau(Paleta.groc, ple: true))
                            .disabled(nou.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    if !ingredients.isEmpty {
                        FlowLayout(espai: 8) {
                            ForEach(ingredients, id: \.self) { ing in
                                XipBoto(text: "\(ing)  ✕", color: Paleta.groc, seleccionat: true) {
                                    withAnimation(Clay.molla) { ingredients.removeAll { $0 == ing } }
                                }
                            }
                        }
                    }
                    Toggle("🫕 Amb la Thermomix", isOn: $thermomix)
                    BotoIA(titol: "✨ Proposa'm 3 receptes", carregant: carregant, accio: demana)
                        .disabled(ingredients.isEmpty)
                    ResultatIA(text: nil, error: error, carregant: carregant)
                }

                ForEach(propostes, id: \.self) { p in
                    PropostaRecepta(recepta: p, alPosarAlMenu: alPosarAlMenu)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    private func afegeix() {
        // Admet diversos separats per comes.
        let nous = nou.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !ingredients.contains($0) }
        guard !nous.isEmpty else { return }
        withAnimation(Clay.molla) { ingredients.append(contentsOf: nous) }
        nou = ""
    }

    private func demana() {
        carregant = true
        error = nil
        Task {
            do {
                let r = try await ServeiReceptes.ambElQueTinc(ingredients, thermomix: thermomix)
                withAnimation(Clay.molla) { propostes = r }
            } catch {
                self.error = error.missatgeIA
            }
            carregant = false
        }
    }
}

private struct PropostaRecepta: View {
    let recepta: ReceptaTraduida
    var alPosarAlMenu: ((Plat) -> Void)?

    var body: some View {
        Targeta(tint: Paleta.verd) {
            HStack(spacing: 12) {
                Text(String(recepta.emoji.prefix(1)))
                    .font(.system(size: 34))
                    .background { BolaClay(color: Paleta.verd, mida: 56) }
                    .frame(width: 58, height: 58)
                VStack(alignment: .leading, spacing: 4) {
                    Text(recepta.nom)
                        .font(.titolSeccio)
                        .foregroundStyle(Paleta.tinta)
                    if recepta.thermomix { Xip(text: "🫕 Thermomix", color: Paleta.cafe, seleccionat: true) }
                }
            }
            DisclosureGroup("Ingredients i passos") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(recepta.ingredients.enumerated()), id: \.offset) { _, ing in
                        Label(ing, systemImage: "circle.fill").labelStyle(PuntLlista())
                    }
                    Divider()
                    ForEach(recepta.passosNumerats, id: \.self) { Text($0) }
                }
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Paleta.tinta)
                .padding(.top, 6)
            }
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .tint(Paleta.verd)
            GuardaReceptaBotons(titol: "Guardar als meus plats", fesPlat: { recepta.comPlat() }, alPosarAlMenu: alPosarAlMenu)
        }
    }
}
