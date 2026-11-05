import Foundation

/// Coses compartides entre l'app i l'extensió de widgets / Live Activity.
enum AppGroup {
    static let id: String = Bundle.main.object(forInfoDictionaryKey: "MariappAppGroup") as? String ?? "group.es.mariapp.app"

    static var defaults: UserDefaults {
        #if os(iOS)
        return UserDefaults(suiteName: id) ?? .standard
        #else
        return .standard
        #endif
    }
}

/// Clau de dia "yyyy-MM-dd" en l'hora local. És l'id dels documents de `Dia`.
enum ClauDia {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func de(_ data: Date) -> String {
        formatter.timeZone = .current
        return formatter.string(from: data)
    }

    static var avui: String { de(Date()) }

    static func data(_ clau: String) -> Date? {
        formatter.timeZone = .current
        return formatter.date(from: clau)
    }
}

/// Foto ràpida del dia de hui, perquè widgets i Live Activity la puguen pintar sense xarxa.
struct HuiSnapshot: Codable, Equatable {
    var dia: String
    var aiguaMl: Int = 0
    var cafes: Int = 0
    var queixes: Int = 0
    var gimnas: Bool = false
    var objectiuMl: Int = 2250
    var ampollaMl: Int = 750

    private static let clau = "hui.snapshot"

    static func carrega() -> HuiSnapshot {
        let avui = ClauDia.avui
        guard let data = AppGroup.defaults.data(forKey: clau),
              var snap = try? JSONDecoder().decode(HuiSnapshot.self, from: data) else {
            return HuiSnapshot(dia: avui)
        }
        if snap.dia != avui {
            snap = HuiSnapshot(dia: avui, objectiuMl: snap.objectiuMl, ampollaMl: snap.ampollaMl)
        }
        return snap
    }

    func desa() {
        if let data = try? JSONEncoder().encode(self) {
            AppGroup.defaults.set(data, forKey: Self.clau)
        }
    }

    var progresAigua: Double {
        guard objectiuMl > 0 else { return 0 }
        return min(Double(aiguaMl) / Double(objectiuMl), 1)
    }
}

/// Accions d'un sol toc (widget, Live Activity, notificacions, Siri).
enum AccioRapida: Codable, Equatable {
    case aigua(ml: Int)
    case cafe(quantitat: Int)
    case queixa
}

struct AccioPendent: Codable, Identifiable {
    var id = UUID()
    var dia: String
    var accio: AccioRapida
    var data: Date
}

/// Cua d'accions fetes fora de l'app (p. ex. des del widget) que l'app envia al núvol quan pot.
enum CuaAccions {
    private static let clau = "accions.pendents"

    static func afegeix(_ accio: AccioPendent) {
        var totes = llegeix()
        totes.append(accio)
        if let data = try? JSONEncoder().encode(totes) {
            AppGroup.defaults.set(data, forKey: clau)
        }
    }

    static func llegeix() -> [AccioPendent] {
        guard let data = AppGroup.defaults.data(forKey: clau),
              let totes = try? JSONDecoder().decode([AccioPendent].self, from: data) else { return [] }
        return totes
    }

    /// Retorna totes les accions pendents i buida la cua.
    static func buida() -> [AccioPendent] {
        let totes = llegeix()
        AppGroup.defaults.removeObject(forKey: clau)
        return totes
    }
}
