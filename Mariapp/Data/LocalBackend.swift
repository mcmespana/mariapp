import Foundation

/// Dades guardades només en aquest dispositiu (un fitxer JSON). S'usa quan encara no hi ha Firebase.
final class LocalBackend: SyncBackend {
    static let shared = LocalBackend()

    let esNuvol = false
    private var dades: [String: [String: [String: Any]]] = [:]
    private var escoltes: [String: [UUID: ([String: [String: Any]]) -> Void]] = [:]
    private let fitxer: URL

    private init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fitxer = dir.appendingPathComponent("mariapp-local.json")
        if let data = try? Data(contentsOf: fitxer),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: [String: [String: Any]]] {
            dades = obj
        }
    }

    /// Totes les dades locals, per a pujar-les al núvol quan es crea la llar.
    func totes() -> [String: [String: [String: Any]]] { dades }

    func buida() {
        dades = [:]
        guarda()
        for colleccio in escoltes.keys { notifica(colleccio) }
    }

    private final class Token: Escolta {
        let accio: () -> Void
        init(_ accio: @escaping () -> Void) { self.accio = accio }
        func atura() { accio() }
    }

    func escolta(_ colleccio: String, _ canvi: @escaping ([String: [String: Any]]) -> Void) -> Escolta {
        let id = UUID()
        escoltes[colleccio, default: [:]][id] = canvi
        let actuals = dades[colleccio] ?? [:]
        DispatchQueue.main.async { canvi(actuals) }
        return Token { [weak self] in self?.escoltes[colleccio]?[id] = nil }
    }

    func desa(_ colleccio: String, id: String, dades nou: [String: Any]) {
        dades[colleccio, default: [:]][id] = nou
        canviat(colleccio)
    }

    func fusiona(_ colleccio: String, id: String, camps: [String: OpCamp]) {
        var doc = dades[colleccio]?[id] ?? [:]
        for (camp, op) in camps {
            switch op {
            case .posa(let valor):
                if let valor { doc[camp] = valor } else { doc.removeValue(forKey: camp) }
            case .suma(let n):
                let actual = (doc[camp] as? NSNumber)?.intValue ?? 0
                doc[camp] = actual + n
            }
        }
        dades[colleccio, default: [:]][id] = doc
        canviat(colleccio)
    }

    func esborra(_ colleccio: String, id: String) {
        dades[colleccio]?[id] = nil
        canviat(colleccio)
    }

    private func canviat(_ colleccio: String) {
        guarda()
        notifica(colleccio)
    }

    private func notifica(_ colleccio: String) {
        let actuals = dades[colleccio] ?? [:]
        let callbacks = Array((escoltes[colleccio] ?? [:]).values)
        DispatchQueue.main.async { callbacks.forEach { $0(actuals) } }
    }

    private func guarda() {
        guard JSONSerialization.isValidJSONObject(dades),
              let data = try? JSONSerialization.data(withJSONObject: dades) else { return }
        try? data.write(to: fitxer, options: .atomic)
    }
}
