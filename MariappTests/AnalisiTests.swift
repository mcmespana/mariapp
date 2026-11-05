import Foundation
import Testing
@testable import Mariapp

struct AnalisiTests {
    private let ara = Ajudants.data("2026-11-15")

    @Test func resumPerMesAgrupaIComptaBe() throws {
        let dies = [
            Ajudants.dia("2026-11-02", aigua: 2000, cafes: 2, gimnas: true, cansament: 400),
            Ajudants.dia("2026-11-03", aigua: 1000, cafes: 0, gimnas: true, cansament: 600, dolor: 2),
            Ajudants.dia("2026-11-04", queixes: 3),
            Ajudants.dia("2026-10-20", gimnas: true),
        ]
        let resums = Analisi.perMes(dies, mesos: 2, ara: ara)

        #expect(resums.count == 2)
        let octubre = try #require(resums.first)
        let novembre = try #require(resums.last)
        #expect(octubre.diesGimnas == 1)
        #expect(novembre.diesGimnas == 2)
        #expect(novembre.cansamentMitja == 500)
        #expect(novembre.aiguaMitjana == 1500)
        #expect(novembre.diesDolor == 1)
        #expect(novembre.queixes == 3)
    }

    @Test func mesosForaDeFinestraNoComptem() {
        let resums = Analisi.perMes([Ajudants.dia("2025-01-10", gimnas: true)], mesos: 3, ara: ara)
        #expect(resums.count == 3)
        #expect(resums.allSatisfy { $0.diesGimnas == 0 })
    }

    @Test func cansamentMitjaEsNilSenseDades() {
        let resums = Analisi.perMes([], mesos: 1, ara: ara)
        #expect(resums.first?.cansamentMitja == nil)
    }

    @Test func cafesVsCansamentAgrupaPerCafes() {
        let dies = [
            Ajudants.dia("2026-11-02", cafes: 0, cansament: 200),
            Ajudants.dia("2026-11-03", cafes: 0, cansament: 400),
            Ajudants.dia("2026-11-04", cafes: 7, cansament: 800),
            Ajudants.dia("2026-11-05", cafes: 3),  // sense cansament: no compta
        ]
        let punts = Analisi.cafesVsCansament(dies)
        #expect(punts.map(\.cafes) == [0, 5])
        #expect(punts[0].cansament == 300)
        #expect(punts[0].dies == 2)
        #expect(punts[1].cansament == 800)
    }

    @Test func cansamentPerDiaDeLaSetmana() {
        // 2026-11-02 és dilluns i 2026-11-09 també.
        let dies = [
            Ajudants.dia("2026-11-02", cansament: 100),
            Ajudants.dia("2026-11-09", cansament: 300),
            Ajudants.dia("2026-11-08", cansament: 900), // diumenge
        ]
        let resultat = Analisi.cansamentPerDiaSetmana(dies)
        #expect(resultat.map(\.diaSetmana) == [1, 7])
        #expect(resultat[0].mitja == 200)
        #expect(resultat[0].nom == "dl")
        #expect(resultat[1].mitja == 900)
    }

    @Test func fraseDeCafesNecessitaDadesSuficients() {
        let pocs = [PuntCafeCansament(cafes: 0, cansament: 300, dies: 1)]
        #expect(Analisi.fraseCafes(pocs, escala: 1000) == nil)
    }

    @Test func resumPerIANoIncloNotesPersonals() {
        var d = Ajudants.dia("2026-11-02", aigua: 1500, cansament: 500)
        d.nota = "SECRET personal"
        let resums = Analisi.perMes([d], mesos: 1, ara: ara)
        let text = Analisi.resumPerIA(resums: resums, cafes: [], diaSetmana: [], escala: 1000, objectiuMl: 2250)
        #expect(!text.contains("SECRET"))
        #expect(text.contains("cansament 500"))
    }
}
