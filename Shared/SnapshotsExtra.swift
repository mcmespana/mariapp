import Foundation

/// Foto de la pròxima cita del metge (l'escriu l'app, la llig el widget).
struct CitaSnapshot: Codable, Equatable {
    var titol: String
    var emoji: String
    var data: Date
    var lloc: String

    private static let clau = "proxima.cita"

    /// Només torna la cita si encara no ha passat.
    static func carrega(ara: Date = Date()) -> CitaSnapshot? {
        guard let dades = AppGroup.defaults.data(forKey: clau),
              let snap = try? JSONDecoder().decode(CitaSnapshot.self, from: dades),
              snap.data > ara else { return nil }
        return snap
    }

    static func desa(_ snap: CitaSnapshot?) {
        if let snap, let dades = try? JSONEncoder().encode(snap) {
            AppGroup.defaults.set(dades, forKey: clau)
        } else {
            AppGroup.defaults.removeObject(forKey: clau)
        }
    }
}

/// Dinar i sopar d'un dia, ja convertits a text ("🎃 Crema de carabassa").
struct ParellaMenu: Codable, Equatable {
    var dinar: String?
    var sopar: String?
}

/// Menú dels pròxims 7 dies, perquè el widget el pinte encara que l'app estiga tancada.
struct MenuSnapshot: Codable, Equatable {
    /// Clau: "yyyy-MM-dd" (`ClauDia`).
    var dies: [String: ParellaMenu] = [:]

    private static let clau = "menu.snapshot"

    static func carrega() -> MenuSnapshot {
        guard let dades = AppGroup.defaults.data(forKey: clau),
              let snap = try? JSONDecoder().decode(MenuSnapshot.self, from: dades) else { return MenuSnapshot() }
        return snap
    }

    func desa() {
        if let dades = try? JSONEncoder().encode(self) {
            AppGroup.defaults.set(dades, forKey: Self.clau)
        }
    }

    func per(_ data: Date) -> ParellaMenu? { dies[ClauDia.de(data)] }
}
