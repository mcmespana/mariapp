import Foundation

/// Integració amb Claude (API d'Anthropic) per a suggeriments: plats, menú, anàlisi de dades…
/// La clau es posa a Ajustos i es guarda al Clauer d'aquest dispositiu.
enum ServeiIA {
    static let modelRapid = "claude-haiku-5-5"
    static let modelBo = "claude-sonnet-5-5"

    private static let clauClauer = "anthropic.apiKey"

    static var clau: String? {
        get { Clauer.llig(clauClauer) }
        set { Clauer.desa(newValue, clau: clauClauer) }
    }

    static var configurada: Bool { !(clau ?? "").isEmpty }

    enum ErrorIA: LocalizedError {
        case senseClau
        case resposta(String)

        var errorDescription: String? {
            switch self {
            case .senseClau: "Falta la clau de l'API a Ajustos."
            case .resposta(let m): m
            }
        }
    }

    /// Instruccions base: to i idioma de l'app.
    static let sistemaBase = """
    Eres l'assistent de Mariapp, l'app personal de la Maria (i de David, el seu home).
    Respon SEMPRE en valencià (normatiu AVL però proper i col·loquial, de poble), breu, càlid i amb algun emoji.
    Tenen una Thermomix (TM6). A la Maria li encanten els sopars lleugers.
    """

    /// Fa una pregunta i torna el text de la resposta.
    static func pregunta(_ missatge: String, sistema: String = sistemaBase, model: String? = nil, maxTokens: Int = 2000) async throws -> String {
        guard let clau, !clau.isEmpty else { throw ErrorIA.senseClau }

        var peticio = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        peticio.httpMethod = "POST"
        peticio.timeoutInterval = 120
        peticio.setValue(clau, forHTTPHeaderField: "x-api-key")
        peticio.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        peticio.setValue("application/json", forHTTPHeaderField: "content-type")

        let cos: [String: Any] = [
            "model": model ?? Preferencies.shared.modelIA,
            "max_tokens": maxTokens,
            "system": sistema,
            "messages": [["role": "user", "content": missatge]],
        ]
        peticio.httpBody = try JSONSerialization.data(withJSONObject: cos)

        let (data, resposta) = try await URLSession.shared.data(for: peticio)
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]

        if let http = resposta as? HTTPURLResponse, http.statusCode != 200 {
            let msg = (json["error"] as? [String: Any])?["message"] as? String ?? "Error \(http.statusCode)"
            throw ErrorIA.resposta(msg)
        }
        if (json["stop_reason"] as? String) == "refusal" {
            throw ErrorIA.resposta("Ara mateix no puc ajudar amb això.")
        }
        let blocs = json["content"] as? [[String: Any]] ?? []
        let text = blocs.filter { $0["type"] as? String == "text" }.compactMap { $0["text"] as? String }.joined(separator: "\n")
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: JSON

    /// Fa una pregunta i decodifica la resposta com a JSON. Reintenta una vegada si no es pot llegir.
    static func json<T: Decodable>(
        _ missatge: String,
        tipus: T.Type,
        sistema: String = sistemaBase,
        model: String? = nil,
        maxTokens: Int = 2000
    ) async throws -> T {
        let sistemaJSON = sistema + "\nRespon NOMÉS amb JSON vàlid, sense cap text abans ni després i sense blocs de codi (```)."
        for _ in 0..<2 {
            let text = try await pregunta(missatge, sistema: sistemaJSON, model: model, maxTokens: maxTokens)
            if let valor = decodifica(text, tipus: tipus) { return valor }
        }
        throw ErrorIA.resposta("No he entés la resposta de la IA. Torna-ho a provar 🙏")
    }

    /// Extrau el primer bloc `[…]` o `{…}` d'un text (per si la IA afig frases al voltant).
    static func blocJSON(_ text: String) -> String? {
        let claus: [(Character, Character)] = [("[", "]"), ("{", "}")]
        var candidats: [Range<String.Index>] = []
        for (obre, tanca) in claus {
            if let a = text.firstIndex(of: obre), let b = text.lastIndex(of: tanca), a < b {
                candidats.append(a..<text.index(after: b))
            }
        }
        guard let millor = candidats.min(by: { $0.lowerBound < $1.lowerBound }) else { return nil }
        return String(text[millor])
    }

    static func decodifica<T: Decodable>(_ text: String, tipus: T.Type) -> T? {
        guard let bloc = blocJSON(text), let data = bloc.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(tipus, from: data)
    }
}
