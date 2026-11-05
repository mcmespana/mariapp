import Foundation

// Receptes del món (TheMealDB, gratuïta i sense clau) + traducció al valencià amb la IA.
// Tot el que es pot provar sense xarxa (parseig, conversió a `Plat`) viu en funcions pures.

struct IngredientExtern: Hashable {
    var nom: String
    var mesura: String

    /// "200 g Pasta"
    var text: String { mesura.isEmpty ? nom : "\(mesura) \(nom)" }
}

/// Una recepta de TheMealDB (en anglés). Les llistes de `filter.php` només porten id, nom i foto: `esResum`.
struct ReceptaExterna: Identifiable, Hashable {
    var id: String
    var nom: String
    var categoria: String?
    var area: String?
    var instruccions: String = ""
    var imatge: URL?
    var youtube: URL?
    var font: URL?
    var ingredients: [IngredientExtern] = []

    var esResum: Bool { instruccions.isEmpty && ingredients.isEmpty }

    /// Paràgrafs de les instruccions, sense línies buides.
    var paragrafs: [String] {
        instruccions.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Guardar-la tal qual (en anglés), per si no hi ha IA.
    func comPlatSenseTraduir() -> Plat {
        var p = Plat(nom: nom)
        p.ingredients = ingredients.map { Ingredient(nom: $0.text) }
        p.recepta = paragrafs.joined(separator: "\n")
        omple(&p)
        return p
    }

    /// Camps comuns: enllaç, foto i d'on ve.
    fileprivate func omple(_ p: inout Plat) {
        p.enllac = (font ?? youtube)?.absoluteString
        p.imatgeURL = imatge?.absoluteString
        p.notes = "Recepta de TheMealDB" + (area.map { " (\($0))" } ?? "")
    }
}

/// El que torna la IA en traduir (o inventar) una recepta.
struct ReceptaTraduida: Codable, Equatable, Hashable {
    var nom: String
    var emoji: String = "🍲"
    var etiquetes: [String] = []
    var thermomix: Bool = false
    var ingredients: [String] = []
    var passos: [String] = []

    init(nom: String, emoji: String = "🍲", etiquetes: [String] = [], thermomix: Bool = false, ingredients: [String] = [], passos: [String] = []) {
        self.nom = nom
        self.emoji = emoji
        self.etiquetes = etiquetes
        self.thermomix = thermomix
        self.ingredients = ingredients
        self.passos = passos
    }

    /// Tolerant: si la IA es deixa un camp, no passa res.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nom = try c.decodeIfPresent(String.self, forKey: .nom) ?? "Recepta sense nom"
        emoji = try c.decodeIfPresent(String.self, forKey: .emoji) ?? "🍲"
        etiquetes = try c.decodeIfPresent([String].self, forKey: .etiquetes) ?? []
        thermomix = try c.decodeIfPresent(Bool.self, forKey: .thermomix) ?? false
        ingredients = try c.decodeIfPresent([String].self, forKey: .ingredients) ?? []
        passos = try c.decodeIfPresent([String].self, forKey: .passos) ?? []
    }

    /// Passos numerats ("1. …"), sense duplicar la numeració si la IA ja l'ha posada.
    var passosNumerats: [String] {
        passos
            .map { ReceptaTraduida.sensePrefixNumeric($0) }
            .filter { !$0.isEmpty }
            .enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
    }

    static func sensePrefixNumeric(_ pas: String) -> String {
        var text = pas.trimmingCharacters(in: .whitespacesAndNewlines)
        if let rang = text.range(of: #"^\d+\s*[.)\-:]\s*"#, options: .regularExpression) {
            text.removeSubrange(rang)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Converteix la recepta traduïda en un plat. `font` és la recepta original (si n'hi ha) per a la foto i l'enllaç.
    func comPlat(font: ReceptaExterna? = nil) -> Plat {
        var p = Plat(nom: nom.trimmingCharacters(in: .whitespacesAndNewlines))
        p.emoji = emoji.isEmpty ? "🍲" : String(emoji.prefix(1))
        p.etiquetes = etiquetes.compactMap { EtiquetaPlat(rawValue: $0.lowercased()) }
        p.thermomix = thermomix
        p.ingredients = ingredients
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { Ingredient(nom: $0) }
        p.recepta = passosNumerats.joined(separator: "\n")
        font?.omple(&p)
        if font == nil { p.notes = "Recepta inventada per la IA ✨" }
        return p
    }
}

// MARK: - Parseig (pur)

enum ParserReceptes {
    /// `{"meals": null}` o JSON invàlid → llista buida.
    static func parseja(_ data: Data) -> [ReceptaExterna] {
        guard let arrel = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let menjars = arrel["meals"] as? [[String: Any]] else { return [] }
        return menjars.compactMap(recepta(de:))
    }

    static func recepta(de d: [String: Any]) -> ReceptaExterna? {
        guard let id = net(d["idMeal"]), let nom = net(d["strMeal"]) else { return nil }
        // Les claus strIngredient1…20 / strMeasure1…20 són dinàmiques; els buits arriben com "", " " o null.
        var ingredients: [IngredientExtern] = []
        for i in 1...20 {
            guard let ingredient = net(d["strIngredient\(i)"]) else { continue }
            ingredients.append(IngredientExtern(nom: ingredient, mesura: net(d["strMeasure\(i)"]) ?? ""))
        }
        return ReceptaExterna(
            id: id,
            nom: nom,
            categoria: net(d["strCategory"]),
            area: net(d["strArea"]),
            instruccions: net(d["strInstructions"])?.replacingOccurrences(of: "\r\n", with: "\n") ?? "",
            imatge: url(d["strMealThumb"]),
            youtube: url(d["strYoutube"]),
            font: url(d["strSource"]),
            ingredients: ingredients
        )
    }

    private static func net(_ valor: Any?) -> String? {
        guard let text = valor as? String else { return nil }
        let retallat = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return retallat.isEmpty ? nil : retallat
    }

    private static func url(_ valor: Any?) -> URL? {
        guard let text = net(valor), let url = URL(string: text), url.scheme?.hasPrefix("http") == true else { return nil }
        return url
    }
}

// MARK: - Servei

enum ServeiReceptes {
    private static let base = URL(string: "https://www.themealdb.com/api/json/v1/1/")!

    enum ErrorReceptes: LocalizedError {
        case senseConnexio
        case servidor

        var errorDescription: String? {
            switch self {
            case .senseConnexio: "No hi ha connexió 📡"
            case .servidor: "TheMealDB no respon ara mateix. Torna-ho a provar en un moment 🍽️"
            }
        }
    }

    /// Categories de TheMealDB amb nom en valencià per als xips.
    struct Categoria: Identifiable {
        let nom: String
        let api: String
        var id: String { api }
    }

    static let categories: [Categoria] = [
        Categoria(nom: "Pasta", api: "Pasta"), Categoria(nom: "Peix i marisc", api: "Seafood"),
        Categoria(nom: "Vegetarià", api: "Vegetarian"), Categoria(nom: "Vegà", api: "Vegan"),
        Categoria(nom: "Pollastre", api: "Chicken"), Categoria(nom: "Vedella", api: "Beef"),
        Categoria(nom: "Porc", api: "Pork"), Categoria(nom: "Xai", api: "Lamb"),
        Categoria(nom: "Entrants", api: "Starter"), Categoria(nom: "Acompanyaments", api: "Side"),
        Categoria(nom: "Esmorzar", api: "Breakfast"), Categoria(nom: "Postres", api: "Dessert"),
    ]

    static func cerca(_ nom: String) async throws -> [ReceptaExterna] {
        ParserReceptes.parseja(try await dades("search.php", ["s": nom]))
    }

    static func perIngredient(_ ingredient: String) async throws -> [ReceptaExterna] {
        let api = ingredient.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "_")
        return ParserReceptes.parseja(try await dades("filter.php", ["i": api]))
    }

    static func perCategoria(_ categoria: String) async throws -> [ReceptaExterna] {
        ParserReceptes.parseja(try await dades("filter.php", ["c": categoria]))
    }

    static func espanyoles() async throws -> [ReceptaExterna] {
        ParserReceptes.parseja(try await dades("filter.php", ["a": "Spanish"]))
    }

    static func detall(id: String) async throws -> ReceptaExterna? {
        ParserReceptes.parseja(try await dades("lookup.php", ["i": id])).first
    }

    static func aleatoria() async throws -> ReceptaExterna? {
        ParserReceptes.parseja(try await dades("random.php", [:])).first
    }

    /// Cerca pensada per a la Maria: si hi ha IA, la consulta (en valencià) es tradueix a l'anglés abans;
    /// si no troba cap plat amb eixe nom, prova com a ingredient.
    static func cercaDelUsuari(_ text: String) async throws -> [ReceptaExterna] {
        let consulta = await traduixConsulta(text)
        let perNom = try await cerca(consulta)
        if !perNom.isEmpty { return perNom }
        return try await perIngredient(consulta)
    }

    static func traduixConsulta(_ text: String) async -> String {
        let net = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard ServeiIA.configurada, !net.isEmpty else { return net }
        let resposta = try? await ServeiIA.pregunta(
            "Tradueix a l'anglés esta cerca de cuina (és el nom d'un plat o d'un ingredient): \(net)",
            sistema: "Respon només amb la traducció, sense cometes ni punt final.",
            model: ServeiIA.modelRapid,
            maxTokens: 50
        )
        let traduccio = resposta?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return traduccio.isEmpty || traduccio.count > 60 ? net : traduccio
    }

    private static func dades(_ ruta: String, _ consulta: [String: String]) async throws -> Data {
        guard var components = URLComponents(url: base.appendingPathComponent(ruta), resolvingAgainstBaseURL: false) else {
            throw ErrorReceptes.servidor
        }
        if !consulta.isEmpty { components.queryItems = consulta.map { URLQueryItem(name: $0.key, value: $0.value) } }
        guard let url = components.url else { throw ErrorReceptes.servidor }
        var peticio = URLRequest(url: url)
        peticio.timeoutInterval = 20
        do {
            let (data, resposta) = try await URLSession.shared.data(for: peticio)
            if let http = resposta as? HTTPURLResponse, http.statusCode != 200 { throw ErrorReceptes.servidor }
            return data
        } catch let error as ErrorReceptes {
            throw error
        } catch {
            throw ErrorReceptes.senseConnexio
        }
    }

    // MARK: Traducció amb IA

    static func promptTraduccio(_ r: ReceptaExterna, thermomix: Bool) -> String {
        let ingredients = r.ingredients.map { "- \($0.text)" }.joined(separator: "\n")
        let norma = thermomix
            ? "- Adapta els passos a la Thermomix TM6: en cada pas que es puga fer amb ella, indica temps / temperatura / velocitat (p. ex. «5 min / 100 °C / vel. 2») i posa \"thermomix\": true."
            : "- \"thermomix\": false (fes-ho de la manera tradicional)."
        return """
        Tradueix i adapta esta recepta al valencià (normatiu AVL però proper i col·loquial).
        Nom original: \(r.nom)\(r.categoria.map { " · Categoria: \($0)" } ?? "")\(r.area.map { " · Cuina: \($0)" } ?? "")

        Ingredients:
        \(ingredients.isEmpty ? "(sense llista)" : ingredients)

        Instruccions:
        \(r.instruccions.isEmpty ? "(sense instruccions)" : r.instruccions)

        Normes:
        - "nom": el nom del plat en valencià, curt.
        - "emoji": UN sol emoji que represente el plat.
        - "etiquetes": només d'entre lleuger, contundent, dinar, sopar, tupper, rapid (les que encaixen, màxim 3).
        - "ingredients": una cadena per ingredient amb la quantitat en sistema mètric (tasses → g o ml, ounces → g…), p. ex. "200 g de pasta".
        - "passos": passos breus i clars, un per element, SENSE numerar.
        \(norma)
        Format: {"nom": "...", "emoji": "🍝", "etiquetes": ["dinar"], "thermomix": false, "ingredients": ["..."], "passos": ["..."]}
        """
    }

    static func tradueix(_ recepta: ReceptaExterna, thermomix: Bool) async throws -> ReceptaTraduida {
        try await ServeiIA.json(promptTraduccio(recepta, thermomix: thermomix), tipus: ReceptaTraduida.self, maxTokens: 2500)
    }

    /// "Què faig amb el que tinc?": 3 propostes completes a partir dels ingredients.
    static func promptIngredients(_ ingredients: [String], thermomix: Bool) -> String {
        let forma = thermomix
            ? "Fes-les amb la Thermomix TM6: en cada pas indica temps / temperatura / velocitat i posa \"thermomix\": true."
            : "Fes-les de la manera tradicional (\"thermomix\": false)."
        return """
        Tinc estos ingredients a casa: \(ingredients.joined(separator: ", ")).
        Proposa'm 3 receptes diferents que es puguen fer sobretot amb això (pots suposar que hi ha oli, sal i aigua, i com a màxim 2 o 3 ingredients més).
        \(forma)
        Per a cada recepta: "nom" en valencià (curt), "emoji" (UN sol), "etiquetes" només d'entre lleuger, contundent, dinar, sopar, tupper, rapid, "ingredients" (cadenes amb quantitat en sistema mètric) i "passos" (breus, un per element, SENSE numerar).
        Format: [{"nom": "...", "emoji": "🍲", "etiquetes": ["sopar"], "thermomix": false, "ingredients": ["..."], "passos": ["..."]}]
        """
    }

    static func ambElQueTinc(_ ingredients: [String], thermomix: Bool) async throws -> [ReceptaTraduida] {
        let resultat = try await ServeiIA.json(promptIngredients(ingredients, thermomix: thermomix), tipus: [ReceptaTraduida].self, maxTokens: 3500)
        return Array(resultat.prefix(3))
    }
}
