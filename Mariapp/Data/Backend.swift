import Foundation

/// Operació sobre un camp d'un document (per a fusionar sense haver de llegir abans).
enum OpCamp {
    /// Posa un valor. `nil` esborra el camp.
    case posa(Any?)
    /// Suma (o resta) atòmicament.
    case suma(Int)
}

protocol Escolta: AnyObject {
    func atura()
}

/// On viuen les dades. Hi ha dos: `LocalBackend` (només en aquest dispositiu)
/// i `FirestoreBackend` (núvol, compartit entre dispositius i amb David).
protocol SyncBackend: AnyObject {
    var esNuvol: Bool { get }
    func escolta(_ colleccio: String, _ canvi: @escaping ([String: [String: Any]]) -> Void) -> Escolta
    func desa(_ colleccio: String, id: String, dades: [String: Any])
    func fusiona(_ colleccio: String, id: String, camps: [String: OpCamp])
    func esborra(_ colleccio: String, id: String)
}

/// Conversió Registre <-> diccionari. Dates com a segons des de 1970 (Double).
enum Codificador {
    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .secondsSince1970
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }()

    static func diccionari<T: Encodable>(_ valor: T) -> [String: Any] {
        guard let data = try? encoder.encode(valor),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
        return obj
    }

    static func registre<T: Decodable>(_ tipus: T.Type, id: String, dades: [String: Any]) -> T? {
        var dades = dades
        dades["id"] = id
        guard JSONSerialization.isValidJSONObject(dades),
              let data = try? JSONSerialization.data(withJSONObject: dades) else { return nil }
        do {
            return try decoder.decode(tipus, from: data)
        } catch {
            print("⚠️ No s'ha pogut llegir \(tipus) \(id): \(error)")
            return nil
        }
    }
}
