import Foundation
import Testing
@testable import Mariapp

struct LocalBackendTests {
    private let backend = LocalBackend.shared

    /// Llig una vegada l'estat d'una col·lecció.
    private func llig(_ colleccio: String) async -> [String: [String: Any]] {
        await withCheckedContinuation { continuacio in
            var resolt = false
            var token: Escolta?
            token = backend.escolta(colleccio) { docs in
                guard !resolt else { return }
                resolt = true
                token?.atura()
                continuacio.resume(returning: docs)
            }
        }
    }

    @Test func fusionaSumaAtomicament() async {
        let col = "test-\(UUID().uuidString)"
        backend.fusiona(col, id: "d", camps: ["aiguaMl": .suma(250)])
        backend.fusiona(col, id: "d", camps: ["aiguaMl": .suma(500)])
        backend.fusiona(col, id: "d", camps: ["aiguaMl": .suma(-100)])

        let docs = await llig(col)
        #expect((docs["d"]?["aiguaMl"] as? NSNumber)?.intValue == 650)
        backend.esborra(col, id: "d")
    }

    @Test func fusionaPosaIEsborraCamps() async {
        let col = "test-\(UUID().uuidString)"
        backend.fusiona(col, id: "d", camps: ["nota": .posa("hola"), "cafes": .suma(1)])
        backend.fusiona(col, id: "d", camps: ["nota": .posa(nil)])

        let docs = await llig(col)
        #expect(docs["d"]?["nota"] == nil)
        #expect((docs["d"]?["cafes"] as? NSNumber)?.intValue == 1)
        backend.esborra(col, id: "d")
    }

    @Test func desaIEsborra() async {
        let col = "test-\(UUID().uuidString)"
        backend.desa(col, id: "a", dades: ["x": 1])
        let desat = await llig(col)
        #expect(desat.keys.contains("a"))
        backend.esborra(col, id: "a")
        let esborrat = await llig(col)
        #expect(esborrat.isEmpty)
    }
}
