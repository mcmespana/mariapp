import Foundation

/// Tot el que es guarda al núvol és un `Registre`: Codable, amb un `id` String i una col·lecció.
///
/// ⚠️ Regla d'or per a afegir camps nous: han de ser opcionals o tindre valor per defecte
/// en un `init(from:)` propi, perquè els documents antics no els tenen.
protocol Registre: Codable, Identifiable, Hashable where ID == String {
    static var colleccio: String { get }
    var id: String { get }
}

// MARK: - Dia (hàbits)

/// Un document per dia ("2026-11-04"). Els comptadors es sumen amb operacions atòmiques,
/// així mai es perd res encara que s'apunte des de diversos llocs alhora.
struct Dia: Registre {
    static let colleccio = "dies"

    var id: String
    var aiguaMl: Int = 0
    var cafes: Int = 0
    var queixes: Int = 0
    var gimnas: Bool = false
    /// 0...escala (per defecte 1000, el cansòmetre). nil = no apuntat.
    var cansament: Int?
    /// 0 gens, 1 un poquet, 2 prou, 3 molt. nil = no apuntat.
    var dolor: Int?
    var nota: String?

    init(id: String) { self.id = id }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        aiguaMl = try c.decodeIfPresent(Int.self, forKey: .aiguaMl) ?? 0
        cafes = try c.decodeIfPresent(Int.self, forKey: .cafes) ?? 0
        queixes = try c.decodeIfPresent(Int.self, forKey: .queixes) ?? 0
        gimnas = try c.decodeIfPresent(Bool.self, forKey: .gimnas) ?? false
        cansament = try c.decodeIfPresent(Int.self, forKey: .cansament)
        dolor = try c.decodeIfPresent(Int.self, forKey: .dolor)
        nota = try c.decodeIfPresent(String.self, forKey: .nota)
    }

    var data: Date { ClauDia.data(id) ?? .distantPast }
    var teDolor: Bool { (dolor ?? 0) > 0 }
}

enum CampDia: String {
    case aiguaMl, cafes, queixes, gimnas, cansament, dolor, nota
}

// MARK: - Configuració compartida

struct Configuracio: Registre {
    static let colleccio = "config"
    static let idGeneral = "general"

    var id: String = Configuracio.idGeneral
    var ampollaMl: Int = 750
    var objectiuMl: Int = 2250
    var escalaCansament: Int = 1000

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? Configuracio.idGeneral
        ampollaMl = try c.decodeIfPresent(Int.self, forKey: .ampollaMl) ?? 750
        objectiuMl = try c.decodeIfPresent(Int.self, forKey: .objectiuMl) ?? 2250
        escalaCansament = try c.decodeIfPresent(Int.self, forKey: .escalaCansament) ?? 1000
    }
}

// MARK: - Menú

enum EtiquetaPlat: String, Codable, CaseIterable, Identifiable {
    case lleuger, contundent, dinar, sopar, tupper, rapid

    var id: String { rawValue }
    var nom: String {
        switch self {
        case .lleuger: "Lleuger"
        case .contundent: "Contundent"
        case .dinar: "Per a dinar"
        case .sopar: "Per a sopar"
        case .tupper: "Per al táper"
        case .rapid: "Ràpid"
        }
    }
    var emoji: String {
        switch self {
        case .lleuger: "🌿"
        case .contundent: "🍖"
        case .dinar: "☀️"
        case .sopar: "🌙"
        case .tupper: "🥡"
        case .rapid: "⚡️"
        }
    }
}

struct Ingredient: Codable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    var nom: String
    var tenim: Bool = true
}

struct Plat: Registre {
    static let colleccio = "plats"

    var id: String = UUID().uuidString
    var nom: String
    var emoji: String = "🍲"
    var etiquetes: [EtiquetaPlat] = []
    var thermomix: Bool = false
    var ingredients: [Ingredient] = []
    var recepta: String = ""
    var enllac: String?
    var notes: String = ""
    var favorit: Bool = false
    var creat: Date = Date()

    init(nom: String) { self.nom = nom }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        nom = try c.decodeIfPresent(String.self, forKey: .nom) ?? "Plat sense nom"
        emoji = try c.decodeIfPresent(String.self, forKey: .emoji) ?? "🍲"
        let crues = try c.decodeIfPresent([String].self, forKey: .etiquetes) ?? []
        etiquetes = crues.compactMap(EtiquetaPlat.init(rawValue:))
        thermomix = try c.decodeIfPresent(Bool.self, forKey: .thermomix) ?? false
        ingredients = try c.decodeIfPresent([Ingredient].self, forKey: .ingredients) ?? []
        recepta = try c.decodeIfPresent(String.self, forKey: .recepta) ?? ""
        enllac = try c.decodeIfPresent(String.self, forKey: .enllac)
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        favorit = try c.decodeIfPresent(Bool.self, forKey: .favorit) ?? false
        creat = try c.decodeIfPresent(Date.self, forKey: .creat) ?? Date()
    }
}

enum Apat: String, Codable, CaseIterable, Identifiable {
    case dinar, sopar
    var id: String { rawValue }
    var nom: String { self == .dinar ? "Dinar" : "Sopar" }
}

struct EntradaMenu: Codable, Hashable {
    var platId: String?
    /// Text lliure quan no és un plat guardat ("Sopar fora 🎉").
    var text: String?
}

/// Un document per setmana ISO ("2026-W45"). Clau de `apats`: "<dia 1-7>-<apat>", 1 = dilluns.
struct MenuSetmana: Registre {
    static let colleccio = "menus"

    var id: String
    var apats: [String: EntradaMenu] = [:]

    init(id: String) { self.id = id }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        apats = try c.decodeIfPresent([String: EntradaMenu].self, forKey: .apats) ?? [:]
    }

    static func clau(dia: Int, apat: Apat) -> String { "\(dia)-\(apat.rawValue)" }

    static func id(per data: Date) -> String {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .current
        let c = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: data)
        return String(format: "%04d-W%02d", c.yearForWeekOfYear ?? 2000, c.weekOfYear ?? 1)
    }
}

// MARK: - Metges

struct CategoriaMetge: Registre {
    static let colleccio = "categoriesMetge"

    var id: String = UUID().uuidString
    var nom: String
    var emoji: String
    var ordre: Int = 0

    init(id: String = UUID().uuidString, nom: String, emoji: String, ordre: Int = 0) {
        self.id = id; self.nom = nom; self.emoji = emoji; self.ordre = ordre
    }

    static let perDefecte: [CategoriaMetge] = [
        .init(id: "capcalera", nom: "Metgessa de capçalera", emoji: "🩺", ordre: 0),
        .init(id: "gine", nom: "Ginecologia", emoji: "🌸", ordre: 1),
        .init(id: "uro", nom: "Urologia", emoji: "💧", ordre: 2),
        .init(id: "dentista", nom: "Dentista", emoji: "🦷", ordre: 3),
        .init(id: "analitiques", nom: "Analítiques", emoji: "🧪", ordre: 4),
        .init(id: "ulls", nom: "Oculista", emoji: "👁️", ordre: 5),
        .init(id: "pell", nom: "Dermatologia", emoji: "🧴", ordre: 6),
        .init(id: "altres", nom: "Altres", emoji: "🏥", ordre: 7),
    ]
}

enum EstatCita: String, Codable, CaseIterable, Identifiable {
    /// "Tinc que demanar cita"
    case perDemanar
    /// Ja tinc dia i hora
    case programada
    case feta

    var id: String { rawValue }
    var nom: String {
        switch self {
        case .perDemanar: "Cal demanar cita"
        case .programada: "Tinc cita"
        case .feta: "Feta"
        }
    }
}

struct Cita: Registre {
    static let colleccio = "cites"

    var id: String = UUID().uuidString
    var titol: String
    var categoriaId: String = "altres"
    var estat: EstatCita = .perDemanar
    var data: Date?
    var duradaMinuts: Int = 60
    var lloc: String = ""
    var notes: String = ""
    /// Minuts abans de la cita en què salta un avís. Ex: [10080, 1440, 120] = 1 setmana, 1 dia, 2 hores.
    var avisos: [Int] = [1440, 120]
    /// Per a "cal demanar cita": quan vols que t'ho recorde.
    var recordarDemanarEl: Date?
    /// eventIdentifier de l'esdeveniment creat al calendari (si n'hi ha).
    var esdevenimentId: String?
    var creat: Date = Date()

    init(titol: String) { self.titol = titol }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        titol = try c.decodeIfPresent(String.self, forKey: .titol) ?? "Cita"
        categoriaId = try c.decodeIfPresent(String.self, forKey: .categoriaId) ?? "altres"
        estat = (try? c.decodeIfPresent(EstatCita.self, forKey: .estat)) ?? .perDemanar
        data = try c.decodeIfPresent(Date.self, forKey: .data)
        duradaMinuts = try c.decodeIfPresent(Int.self, forKey: .duradaMinuts) ?? 60
        lloc = try c.decodeIfPresent(String.self, forKey: .lloc) ?? ""
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        avisos = try c.decodeIfPresent([Int].self, forKey: .avisos) ?? [1440, 120]
        recordarDemanarEl = try c.decodeIfPresent(Date.self, forKey: .recordarDemanarEl)
        esdevenimentId = try c.decodeIfPresent(String.self, forKey: .esdevenimentId)
        creat = try c.decodeIfPresent(Date.self, forKey: .creat) ?? Date()
    }
}

// MARK: - David

enum TipusPensament: String, Codable, CaseIterable, Identifiable {
    case queixa, agraiment, pensament, bonic, idea

    var id: String { rawValue }
    var nom: String {
        switch self {
        case .queixa: "Queixa"
        case .agraiment: "Agraïment"
        case .pensament: "Pensament"
        case .bonic: "Cosa bonica"
        case .idea: "Idea / pla"
        }
    }
    var emoji: String {
        switch self {
        case .queixa: "😤"
        case .agraiment: "🙏"
        case .pensament: "💭"
        case .bonic: "🥰"
        case .idea: "💡"
        }
    }
}

struct Pensament: Registre {
    static let colleccio = "pensaments"

    var id: String = UUID().uuidString
    var tipus: TipusPensament = .pensament
    var text: String
    var data: Date = Date()

    init(tipus: TipusPensament, text: String) { self.tipus = tipus; self.text = text }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        tipus = (try? c.decodeIfPresent(TipusPensament.self, forKey: .tipus)) ?? .pensament
        text = try c.decodeIfPresent(String.self, forKey: .text) ?? ""
        data = try c.decodeIfPresent(Date.self, forKey: .data) ?? Date()
    }
}

// MARK: - Calendari

enum Propietari: String, Codable, CaseIterable, Identifiable {
    case maria, david, tots
    var id: String { rawValue }
    var nom: String {
        switch self {
        case .maria: "Maria"
        case .david: "David"
        case .tots: "Els dos"
        }
    }
    var emoji: String {
        switch self {
        case .maria: "🌻"
        case .david: "🐻"
        case .tots: "💛"
        }
    }
}

enum ColorEtiqueta: String, Codable, CaseIterable, Identifiable {
    case aigua, blau, verd, groc, taronja, cafe
    var id: String { rawValue }
}

/// Decoració pròpia d'un esdeveniment del calendari compartit (Google Calendar via iOS).
/// L'id és un hash de l'identificador extern de l'esdeveniment (veure `ServeiCalendari.clau(per:)`).
struct AnotacioEsdeveniment: Registre {
    static let colleccio = "anotacions"

    var id: String
    var propietari: Propietari = .tots
    var emoji: String?
    var color: ColorEtiqueta?
    var nota: String?
    /// Minuts abans per a avisos extra (locals, només al dispositiu de la Maria).
    var avisos: [Int] = []

    init(id: String) { self.id = id }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        propietari = (try? c.decodeIfPresent(Propietari.self, forKey: .propietari)) ?? .tots
        emoji = try c.decodeIfPresent(String.self, forKey: .emoji)
        color = try? c.decodeIfPresent(ColorEtiqueta.self, forKey: .color)
        nota = try c.decodeIfPresent(String.self, forKey: .nota)
        avisos = try c.decodeIfPresent([Int].self, forKey: .avisos) ?? []
    }
}
