import Foundation

/// Càlculs de setmanes ISO (dilluns com a primer dia) per al menú.
enum Setmana {
    static var calendari: Calendar {
        var c = Calendar(identifier: .iso8601)
        c.locale = Dates.locale
        c.timeZone = .current
        return c
    }

    /// Dilluns (a les 00:00) de la setmana que conté `data`.
    static func inici(de data: Date) -> Date {
        calendari.dateInterval(of: .weekOfYear, for: data)?.start ?? calendari.startOfDay(for: data)
    }

    /// Dia `n` (1 = dilluns … 7 = diumenge) de la setmana que comença a `inici`.
    static func dia(_ inici: Date, _ n: Int) -> Date {
        calendari.date(byAdding: .day, value: n - 1, to: inici) ?? inici
    }

    static func mou(_ inici: Date, setmanes: Int) -> Date {
        calendari.date(byAdding: .weekOfYear, value: setmanes, to: inici) ?? inici
    }

    /// 1 = dilluns … 7 = diumenge.
    static func numeroDia(_ data: Date = Date()) -> Int {
        let w = calendari.component(.weekday, from: data) // 1 = diumenge
        return (w + 5) % 7 + 1
    }

    static func numeroSetmana(_ inici: Date) -> Int {
        calendari.component(.weekOfYear, from: inici)
    }

    /// "4 – 10 de novembre" o "28 oct. – 3 nov."
    static func titol(_ inici: Date) -> String {
        let fi = dia(inici, 7)
        let cal = calendari
        let d1 = cal.component(.day, from: inici)
        let d2 = cal.component(.day, from: fi)
        if cal.component(.month, from: inici) == cal.component(.month, from: fi) {
            return "\(d1) – \(d2) \(deMes(fi))"
        }
        return "\(d1) \(Dates.mes(inici)) – \(d2) \(Dates.mes(fi))"
    }

    /// "de novembre" / "d'octubre".
    static func deMes(_ data: Date) -> String {
        let nom = data.formatted(.dateTime.month(.wide).locale(Dates.locale))
        let vocals = "aeiouàèéíòóú"
        if let primera = nom.lowercased().first, vocals.contains(primera) {
            return "d'\(nom)"
        }
        return "de \(nom)"
    }

    static func nomDia(_ n: Int) -> String {
        Analisi.nomsDiesLlargs[max(1, min(7, n)) - 1].capitalizedFirst
    }
}

extension Apat {
    var emoji: String { self == .dinar ? "☀️" : "🌙" }
    var etiqueta: EtiquetaPlat { self == .dinar ? .dinar : .sopar }
}

extension MenuSetmana {
    /// L'entrada d'un forat, si té alguna cosa.
    func entrada(dia: Int, apat: Apat) -> EntradaMenu? {
        guard let e = apats[Self.clau(dia: dia, apat: apat)],
              e.platId != nil || !(e.text ?? "").isEmpty else { return nil }
        return e
    }

    mutating func posa(_ entrada: EntradaMenu?, dia: Int, apat: Apat) {
        let clau = Self.clau(dia: dia, apat: apat)
        if let entrada {
            apats[clau] = entrada
        } else {
            apats.removeValue(forKey: clau)
        }
    }

    /// Ids dels plats guardats que hi ha esta setmana.
    var platIds: Set<String> {
        Set(apats.values.compactMap(\.platId))
    }
}

extension Plat {
    /// Filtre del llistat: text (sense accents ni majúscules) i etiquetes (han de tindre-les totes).
    func passa(cerca: String, etiquetes: Set<EtiquetaPlat> = [], nomesThermomix: Bool = false, nomesPreferits: Bool = false) -> Bool {
        if nomesThermomix && !thermomix { return false }
        if nomesPreferits && !favorit { return false }
        if !etiquetes.isSubset(of: Set(self.etiquetes)) { return false }
        let q = Plat.normalitza(cerca)
        if q.isEmpty { return true }
        return Plat.normalitza(nom).contains(q) || ingredients.contains { Plat.normalitza($0.nom).contains(q) }
    }

    static func normalitza(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Dates.locale)
    }

    /// Plat de mostra amb id estable (perquè dos dispositius no dupliquen els d'exemple).
    static func exemple(_ id: String, _ nom: String, _ emoji: String, _ etiquetes: [EtiquetaPlat], thermomix: Bool = false, _ ingredients: [String], recepta: String = "") -> Plat {
        var p = Plat(nom: nom)
        p.id = "exemple-\(id)"
        p.emoji = emoji
        p.etiquetes = etiquetes
        p.thermomix = thermomix
        p.ingredients = ingredients.enumerated().map { Ingredient(id: "exemple-\(id)-\($0.offset)", nom: $0.element, tenim: true) }
        p.recepta = recepta
        return p
    }

    static let exemples: [Plat] = [
        .exemple("crema-carabassa", "Crema de carabassa", "🎃", [.lleuger, .sopar], thermomix: true,
                 ["Carabassa", "Ceba", "Porro", "Oli d'oliva", "Sal"],
                 recepta: "Talla-ho tot a trossos. Thermomix: 3 min a 100 °C vel. 4 amb l'oli, afig la verdura i l'aigua, 20 min 100 °C vel. 1 i tritura 1 min de vel. 5 a 10."),
        .exemple("truita-carabasseta", "Truita de carabasseta", "🍳", [.lleuger, .sopar, .rapid],
                 ["Ous", "Carabasseta", "Ceba", "Oli d'oliva"]),
        .exemple("amanida-cigrons", "Amanida de cigrons", "🥗", [.lleuger, .dinar, .tupper],
                 ["Cigrons cuits", "Tomaca", "Ceba tendra", "Pebrot", "Oli d'oliva", "Vinagre"]),
        .exemple("salmo-forn", "Salmó al forn", "🐟", [.dinar, .sopar],
                 ["Llom de salmó", "Llima", "Anet", "Oli d'oliva"]),
        .exemple("hummus", "Hummus", "🧆", [.lleuger, .sopar, .rapid], thermomix: true,
                 ["Cigrons cuits", "Tahini", "All", "Llima", "Oli d'oliva", "Comí"]),
        .exemple("arros-forn", "Arròs al forn", "🥘", [.contundent, .dinar],
                 ["Arròs", "Costelleta", "Cigrons", "Tomaca", "All", "Botifarra"]),
        .exemple("lasanya-verdures", "Lasanya de verdures", "🧀", [.contundent, .dinar, .tupper],
                 ["Làmines de pasta", "Carabasseta", "Albergínia", "Beixamel", "Formatge ratllat", "Tomaca fregida"]),
        .exemple("crema-porros", "Crema de porros", "🥣", [.lleuger, .sopar], thermomix: true,
                 ["Porros", "Creïlla", "Oli d'oliva", "Sal"]),
        .exemple("poke-bowl", "Poke bowl", "🍚", [.lleuger, .dinar, .tupper],
                 ["Arròs", "Salmó", "Alvocat", "Edamame", "Pastanaga", "Salsa de soja"]),
        .exemple("gaspatxo", "Gaspatxo", "🍅", [.lleuger, .dinar, .sopar], thermomix: true,
                 ["Tomaca madura", "Pepino", "Pebrot verd", "All", "Pa", "Vinagre", "Oli d'oliva"]),
    ]
}
