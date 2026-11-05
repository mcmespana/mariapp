import SwiftUI

/// Un plat proposat per la IA.
struct IdeaPlat: Decodable, Identifiable {
    var nom: String
    var emoji: String?
    var etiquetes: [String]?
    var thermomix: Bool?
    var ingredients: [String]?
    var id: String { nom }

    func comPlat() -> Plat {
        var p = Plat(nom: nom)
        p.emoji = String((emoji ?? "🍲").prefix(1))
        p.etiquetes = (etiquetes ?? []).compactMap { EtiquetaPlat(rawValue: $0.lowercased()) }
        p.thermomix = thermomix ?? false
        p.ingredients = (ingredients ?? []).map { Ingredient(nom: $0) }
        return p
    }
}

/// "✨ Idees noves amb IA": 3 plats nous segons l'àpat, la temporada i el que ja hi ha.
struct IdeesIA: View {
    let apat: Apat
    let dia: Int
    let menu: MenuSetmana
    /// Es crida quan es tria posar l'idea al forat.
    let posa: (Plat) -> Void

    @Environment(DataStore.self) private var store
    @State private var idees: [IdeaPlat] = []
    @State private var carregant = false
    @State private var error: String?
    @State private var guardats: Set<String> = []

    var body: some View {
        Targeta(tint: Paleta.groc) {
            CapcaleraTargeta(icona: "sparkles", titol: "Idees noves amb IA", color: Paleta.groc)
            BotoIA(titol: idees.isEmpty ? "✨ Idees noves" : "✨ Altres idees", carregant: carregant, accio: demana)
            if carregant || error != nil {
                ResultatIA(text: nil, error: error, carregant: carregant)
            }
            ForEach(idees) { idea in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Text(idea.emoji ?? "🍲").font(.title)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(idea.nom).font(.titolTargeta).foregroundStyle(Paleta.tinta)
                            Text(((idea.thermomix ?? false) ? ["🫕 Thermomix"] : []).joined() + (idea.etiquetes ?? []).joined(separator: " · "))
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(Paleta.tintaSuau)
                        }
                    }
                    if let ing = idea.ingredients, !ing.isEmpty {
                        Text(ing.joined(separator: ", "))
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                    HStack(spacing: 8) {
                        Button(guardats.contains(idea.id) ? "Guardat ✅" : "Guarda'l") {
                            store.plats.desa(idea.comPlat())
                            guardats.insert(idea.id)
                            Sons.toca(.cafe)
                        }
                        .buttonStyle(.suau(Paleta.groc))
                        .disabled(guardats.contains(idea.id))
                        Button("Posa'l ací") {
                            let plat = idea.comPlat()
                            if !guardats.contains(idea.id) { store.plats.desa(plat) }
                            posa(plat)
                        }
                        .buttonStyle(.suau(Paleta.groc, ple: true))
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .clay(Paleta.groc, radi: Clay.radiMitja, elevacio: 0.5)
            }
        }
    }

    private func demana() {
        carregant = true
        error = nil
        Task {
            do {
                let resultat = try await ServeiIA.json(prompt(), tipus: [IdeaPlat].self, maxTokens: 1500)
                idees = Array(resultat.prefix(3))
                guardats = []
            } catch {
                self.error = error.missatgeIA
            }
            carregant = false
        }
    }

    private func prompt() -> String {
        let mes = Date().formatted(.dateTime.month(.wide).locale(Dates.locale))
        let existents = store.plats.items.map(\.nom).sorted().joined(separator: ", ")
        let setmana = menu.apats.compactMap { clau, e -> String? in
            if let id = e.platId, let p = store.plats[id] { return "\(clau): \(p.nom)" }
            return e.text.map { "\(clau): \($0)" }
        }.sorted().joined(separator: "; ")
        return """
        Proposa 3 plats NOUS (que no estiguen a la llista) per a \(Setmana.nomDia(dia).lowercased()) \(apat == .dinar ? "dinar" : "sopar"), \
        de temporada (estem al mes de \(mes)).
        \(apat == .sopar ? "Per al sopar, preferix coses lleugeres." : "")
        Plats que ja tenen: \(existents.isEmpty ? "cap" : existents).
        Menú d'esta setmana: \(setmana.isEmpty ? "buit" : setmana).
        Format: [{"nom": "...", "emoji": "🍲", "etiquetes": ["lleuger","sopar"], "thermomix": true, "ingredients": ["...", "..."]}]
        Les etiquetes només poden ser: lleuger, contundent, dinar, sopar, tupper, rapid. El camp "nom" en valencià.
        """
    }
}

/// Ajuda de la IA en el detall d'un plat: què li falta i recepta per a Thermomix.
struct AjudaIAPlat: View {
    let plat: Plat

    @Environment(DataStore.self) private var store
    @State private var carregantFalta = false
    @State private var carregantTM = false
    @State private var falta: String?
    @State private var errorFalta: String?
    @State private var missatgeTM: String?
    @State private var errorTM: String?

    var body: some View {
        Targeta(tint: Paleta.groc) {
            CapcaleraTargeta(icona: "sparkles", titol: "Ajuda de la IA", color: Paleta.groc)
            BotoIA(titol: "✨ Què li falta a este plat?", carregant: carregantFalta, accio: demanaFalta)
            ResultatIA(text: falta, error: errorFalta, carregant: carregantFalta)
            BotoIA(titol: "✨ Recepta per a Thermomix", carregant: carregantTM, accio: demanaThermomix)
            ResultatIA(text: missatgeTM, error: errorTM, carregant: carregantTM)
        }
    }

    private var descripcio: String {
        let ing = plat.ingredients.map(\.nom).joined(separator: ", ")
        let et = plat.etiquetes.map(\.nom).joined(separator: ", ")
        return "Plat: \(plat.nom). Ingredients: \(ing.isEmpty ? "(sense llista)" : ing). Etiquetes: \(et.isEmpty ? "cap" : et)."
    }

    private func demanaFalta() {
        carregantFalta = true
        falta = nil
        errorFalta = nil
        Task {
            do {
                falta = try await ServeiIA.pregunta("""
                \(descripcio)
                Què li falta a este plat perquè siga complet i equilibrat? Dona 3 o 4 idees breus d'ingredients o d'acompanyaments, en llista amb guions. Sense allargar-te.
                """, maxTokens: 600)
            } catch {
                errorFalta = error.missatgeIA
            }
            carregantFalta = false
        }
    }

    private func demanaThermomix() {
        carregantTM = true
        missatgeTM = nil
        errorTM = nil
        Task {
            do {
                let text = try await ServeiIA.pregunta("""
                \(descripcio)
                Escriu els passos per a fer-lo amb la Thermomix TM6, numerats, amb temps, temperatura i velocitat de cada pas (p. ex. «5 min / 100 °C / vel. 2»). Breu i clar.
                """, maxTokens: 1200)
                var p = store.plats[plat.id] ?? plat
                let titol = "🫕 Thermomix (TM6):"
                p.recepta = p.recepta.isEmpty ? "\(titol)\n\(text)" : "\(p.recepta)\n\n\(titol)\n\(text)"
                p.thermomix = true
                store.plats.desa(p)
                missatgeTM = "Guardada a la recepta ✅"
                Sons.toca(.festa)
            } catch {
                errorTM = error.missatgeIA
            }
            carregantTM = false
        }
    }
}
