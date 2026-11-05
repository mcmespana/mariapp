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

/// Un element pendent de la llista de la compra, tal com el pinta el widget.
struct ItemCompra: Codable, Equatable, Identifiable {
    var id: String
    var nom: String
    var quantitat: String?
    var creat: Date = .distantPast
}

/// Els primers elements pendents de la compra (màxim 12) i quants n'hi ha en total, perquè el widget els pinte
/// i els puga ratllar sense obrir l'app.
struct CompraSnapshot: Codable, Equatable {
    var pendents: [ItemCompra] = []
    var totalPendents: Int = 0

    static let maxim = 12
    private static let clau = "compra.snapshot"

    /// A partir de TOTS els pendents (en qualsevol ordre): ordena per creació i es queda amb els 12 primers.
    static func des(_ tots: [ItemCompra]) -> CompraSnapshot {
        let ordenats = tots.sorted { ($0.creat, $0.id) < ($1.creat, $1.id) }
        return CompraSnapshot(pendents: Array(ordenats.prefix(maxim)), totalPendents: tots.count)
    }

    /// Quants n'hi ha més enllà dels que es veuen.
    var restants: Int { max(0, totalPendents - pendents.count) }

    /// Treu un element a l'instant (optimista). Si no hi era, no fa res.
    mutating func treu(id: String) {
        guard let i = pendents.firstIndex(where: { $0.id == id }) else { return }
        pendents.remove(at: i)
        totalPendents = max(0, totalPendents - 1)
    }

    static func carrega() -> CompraSnapshot {
        guard let dades = AppGroup.defaults.data(forKey: clau),
              let snap = try? JSONDecoder().decode(CompraSnapshot.self, from: dades) else { return CompraSnapshot() }
        return snap
    }

    func desa() {
        if let dades = try? JSONEncoder().encode(self) {
            AppGroup.defaults.set(dades, forKey: Self.clau)
        }
    }
}
