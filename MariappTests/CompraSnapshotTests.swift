import Foundation
import Testing
@testable import Mariapp

struct CompraSnapshotTests {
    private func items(_ n: Int) -> [ItemCompra] {
        (0..<n).map { i in
            ItemCompra(id: "e\(i)", nom: "Cosa \(i)", quantitat: nil, creat: Date(timeIntervalSince1970: 1_800_000_000 + Double(i)))
        }
    }

    @Test func limitaADotzeICompteBeElTotal() {
        let snap = CompraSnapshot.des(items(20))
        #expect(snap.pendents.count == 12)
        #expect(snap.totalPendents == 20)
        #expect(snap.restants == 8)
        #expect(snap.pendents.first?.id == "e0")
        #expect(snap.pendents.last?.id == "e11")
    }

    @Test func ordenaPerCreacioIgnoraLOrdreDEntrada() {
        let snap = CompraSnapshot.des(Array(items(5).reversed()))
        #expect(snap.pendents.map(\.id) == ["e0", "e1", "e2", "e3", "e4"])
        #expect(snap.restants == 0)
    }

    @Test func buidaNoTeRestants() {
        let snap = CompraSnapshot.des([])
        #expect(snap.pendents.isEmpty)
        #expect(snap.totalPendents == 0)
        #expect(snap.restants == 0)
    }

    @Test func treureUnElementEsOptimista() {
        var snap = CompraSnapshot.des(items(15))
        snap.treu(id: "e3")
        #expect(snap.pendents.count == 11)
        #expect(snap.totalPendents == 14)
        #expect(!snap.pendents.contains { $0.id == "e3" })
        // Un que no es veu (o que ja no hi és) no canvia res.
        snap.treu(id: "e14")
        snap.treu(id: "no-existeix")
        #expect(snap.pendents.count == 11)
        #expect(snap.totalPendents == 14)
    }

    @Test func codificaIDescodifica() throws {
        let snap = CompraSnapshot.des(items(3))
        let dades = try JSONEncoder().encode(snap)
        #expect(try JSONDecoder().decode(CompraSnapshot.self, from: dades) == snap)
    }
}

struct AccioRapidaTests {
    private func decodifica(_ json: String) throws -> AccioRapida {
        try JSONDecoder().decode(AccioRapida.self, from: Data(json.utf8))
    }

    @Test func lesAccionsAntiguesSeguixenDecodificantse() throws {
        #expect(try decodifica(#"{"aigua":{"ml":375}}"#) == .aigua(ml: 375))
        #expect(try decodifica(#"{"cafe":{"quantitat":2}}"#) == .cafe(quantitat: 2))
        #expect(try decodifica(#"{"queixa":{}}"#) == .queixa)
    }

    @Test func lesAccionsNovesFanViatge() throws {
        let accions: [AccioRapida] = [.comprat(id: "abc"), .aigua(ml: -250), .queixa]
        for a in accions {
            let dades = try JSONEncoder().encode(a)
            #expect(try JSONDecoder().decode(AccioRapida.self, from: dades) == a)
        }
    }

    @Test func accioPendentAmbCompratFaViatge() throws {
        let pendent = AccioPendent(dia: "2026-11-05", accio: .comprat(id: "xyz"), data: Date(timeIntervalSince1970: 1_800_000_000))
        let dades = try JSONEncoder().encode([pendent])
        let torna = try JSONDecoder().decode([AccioPendent].self, from: dades)
        #expect(torna.first?.accio == .comprat(id: "xyz"))
        #expect(torna.first?.dia == "2026-11-05")
    }
}
