import Foundation
import Observation

enum Rol: String, CaseIterable, Identifiable {
    case maria, david
    var id: String { rawValue }
    var nom: String { self == .maria ? "Maria" : "David" }
}

/// Hora del dia (sense data), per als avisos.
struct Hora: Codable, Hashable, Comparable, Identifiable {
    var hora: Int
    var minut: Int
    var id: String { text }
    var text: String { String(format: "%02d:%02d", hora, minut) }

    static func < (a: Hora, b: Hora) -> Bool { (a.hora, a.minut) < (b.hora, b.minut) }

    var comData: Date {
        Calendar.current.date(bySettingHour: hora, minute: minut, second: 0, of: Date()) ?? Date()
    }

    init(hora: Int, minut: Int) { self.hora = hora; self.minut = minut }
    init(_ data: Date) {
        let c = Calendar.current.dateComponents([.hour, .minute], from: data)
        hora = c.hour ?? 0
        minut = c.minute ?? 0
    }
}

/// Preferències d'aquest dispositiu (no es sincronitzen).
@Observable
final class Preferencies {
    static let shared = Preferencies()

    private let d = UserDefaults.standard

    var rol: Rol? {
        didSet { d.set(rol?.rawValue, forKey: "rol"); Avisos.reprograma() }
    }
    var avisosActius: Bool {
        didSet { d.set(avisosActius, forKey: "avisos.actius"); Avisos.reprograma() }
    }
    var horaCansament: Hora {
        didSet { desa(horaCansament, "avisos.cansament"); Avisos.reprograma() }
    }
    var horesAigua: [Hora] {
        didSet { desa(horesAigua, "avisos.aigua"); Avisos.reprograma() }
    }
    var avisGimnas: Bool {
        didSet { d.set(avisGimnas, forKey: "avisos.gimnas.actiu"); Avisos.reprograma() }
    }
    var horaGimnas: Hora {
        didSet { desa(horaGimnas, "avisos.gimnas"); Avisos.reprograma() }
    }
    var activitatEnDirecte: Bool {
        didSet { d.set(activitatEnDirecte, forKey: "activitat.directe") }
    }
    var sonsActius: Bool {
        didSet { d.set(sonsActius, forKey: "sons.actius") }
    }
    var modelIA: String {
        didSet { d.set(modelIA, forKey: "ia.model") }
    }

    private init() {
        rol = d.string(forKey: "rol").flatMap(Rol.init(rawValue:))
        avisosActius = d.object(forKey: "avisos.actius") as? Bool ?? true
        horaCansament = Self.llig("avisos.cansament") ?? Hora(hora: 18, minut: 30)
        horesAigua = Self.llig("avisos.aigua") ?? [Hora(hora: 10, minut: 30), Hora(hora: 12, minut: 30), Hora(hora: 16, minut: 30), Hora(hora: 19, minut: 30)]
        avisGimnas = d.object(forKey: "avisos.gimnas.actiu") as? Bool ?? true
        horaGimnas = Self.llig("avisos.gimnas") ?? Hora(hora: 21, minut: 30)
        activitatEnDirecte = d.object(forKey: "activitat.directe") as? Bool ?? true
        sonsActius = d.object(forKey: "sons.actius") as? Bool ?? true
        modelIA = d.string(forKey: "ia.model") ?? ServeiIA.modelRapid
    }

    var esMaria: Bool { rol == .maria }

    private func desa<T: Encodable>(_ valor: T, _ clau: String) {
        d.set(try? JSONEncoder().encode(valor), forKey: clau)
    }

    private static func llig<T: Decodable>(_ clau: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: clau) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
