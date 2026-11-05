import Foundation
import Testing
@testable import Mariapp

struct SalutTests {
    private func hora(_ h: Int, _ m: Int = 0, dia: String = "2026-11-04") -> Date {
        ClauDia.data(dia)!.addingTimeInterval(TimeInterval(h * 3600 + m * 60))
    }

    // MARK: Dia antic

    @Test func diaAntiguSenseCampsDeSalutEsDecodifica() throws {
        let json: [String: Any] = ["aiguaMl": 1500, "gimnas": true]
        let d = try #require(Codificador.registre(Dia.self, id: "2026-11-04", dades: json))
        #expect(d.entrenament == nil)
        #expect(d.sonMinuts == nil)
        #expect(d.aiguaMl == 1500)
    }

    @Test func campsDeSalutFanViatge() throws {
        var d = Dia(id: "2026-11-04")
        d.entrenament = "🏋️ Força tradicional · 45 min"
        d.sonMinuts = 440
        let torna = try #require(Codificador.registre(Dia.self, id: d.id, dades: Codificador.diccionari(d)))
        #expect(torna.entrenament == d.entrenament)
        #expect(torna.sonMinuts == 440)
    }

    // MARK: Càlcul del son

    @Test func sumaIntervalsSenseSolapament() {
        let intervals = [
            IntervalSon(inici: hora(0), fi: hora(3), dormit: true),
            IntervalSon(inici: hora(4), fi: hora(7, 30), dormit: true),
        ]
        #expect(CalculSon.minutsDormits(intervals) == 6 * 60 + 30)
    }

    @Test func elsSolapamentsNoEsCompten2Voltes() {
        // El Watch i l'iPhone apunten la mateixa estona: 01:00–05:00 i 03:00–06:00 → 01:00–06:00 = 5 h.
        let intervals = [
            IntervalSon(inici: hora(1), fi: hora(5), dormit: true),
            IntervalSon(inici: hora(3), fi: hora(6), dormit: true),
            IntervalSon(inici: hora(2), fi: hora(3), dormit: true),   // dins d'un altre
        ]
        #expect(CalculSon.minutsDormits(intervals) == 5 * 60)
    }

    @Test func alLlitDespertNoCompta() {
        let intervals = [
            IntervalSon(inici: hora(0), fi: hora(8), dormit: false),
            IntervalSon(inici: hora(1), fi: hora(2), dormit: true),
        ]
        #expect(CalculSon.minutsDormits(intervals) == 60)
        #expect(CalculSon.minutsDormits([]) == 0)
    }

    @Test func retallaALaFinestraDeLaNit() {
        let finestra = CalculSon.finestra(nit: hora(12, dia: "2026-11-04"))
        // De les 18:00 del 3 de novembre a les 12:00 del 4.
        #expect(ClauDia.de(finestra.inici) == "2026-11-03")
        #expect(Calendar.current.component(.hour, from: finestra.inici) == 18)
        #expect(ClauDia.de(finestra.fi) == "2026-11-04")
        #expect(Calendar.current.component(.hour, from: finestra.fi) == 12)

        // Una migdiada de 13:00 a 14:00 queda fora; el son de 22:00 a 23:00 (dia 3) i de 00:00 a 06:00 (dia 4), dins.
        let intervals = [
            IntervalSon(inici: hora(22, dia: "2026-11-03"), fi: hora(23, dia: "2026-11-03"), dormit: true),
            IntervalSon(inici: hora(0), fi: hora(6), dormit: true),
            IntervalSon(inici: hora(13), fi: hora(14), dormit: true),
            // Comença abans de les 18:00: només compta des de les 18:00 → 17:00–19:00 = 1 h dins.
            IntervalSon(inici: hora(17, dia: "2026-11-03"), fi: hora(19, dia: "2026-11-03"), dormit: true),
        ]
        // 22–23 (1 h) + 0–6 (6 h) + 18–19 (1 h) = 8 h
        #expect(CalculSon.minutsDormits(intervals, finestra: finestra) == 8 * 60)
    }

    @Test func textosDeSonIEntrenament() {
        #expect(CalculSon.text(minuts: 440) == "7 h 20 min")
        #expect(CalculSon.text(minuts: 480) == "8 h")
        #expect(CalculSon.text(minuts: 45) == "45 min")
        #expect(CalculSon.textEntrenament(nom: "Força tradicional", minuts: 45) == "🏋️ Força tradicional · 45 min")
    }

    // MARK: Son ↔ cansament

    @Test func tramsDeSon() {
        #expect(TramSon.per(minuts: 359) == .menysDe6)
        #expect(TramSon.per(minuts: 360) == .de6a7_5)
        #expect(TramSon.per(minuts: 449) == .de6a7_5)
        #expect(TramSon.per(minuts: 450) == .mesDe7_5)
    }

    private func dia(_ n: Int, son: Int?, cansament: Int?) -> Dia {
        var d = Ajudants.dia(String(format: "2026-10-%02d", n), cansament: cansament)
        d.sonMinuts = son
        return d
    }

    @Test func sonVsCansamentIgnoraDiesIncomplets() {
        let dies = [
            dia(1, son: 300, cansament: 800),
            dia(2, son: 300, cansament: nil),   // sense cansament
            dia(3, son: nil, cansament: 500),   // sense son
            dia(4, son: 500, cansament: 200),
        ]
        let punts = Analisi.sonVsCansament(dies)
        #expect(punts.map(\.tram) == [.menysDe6, .mesDe7_5])
        #expect(punts[0].cansamentMitja == 800)
        #expect(punts[1].dies == 1)
    }

    @Test func fraseDeSonNecessitaCincDiesIDiuQueDormirCompta() throws {
        let poc = (1...5).map { dia($0, son: 300, cansament: 700) }
        let molt = (11...15).map { dia($0, son: 500, cansament: 300) }
        #expect(Analisi.fraseSonCansament(Analisi.sonVsCansament(Array(poc.prefix(4)) + molt), escala: 1000) == nil)
        let frase = try #require(Analisi.fraseSonCansament(Analisi.sonVsCansament(poc + molt), escala: 1000))
        #expect(frase.contains("Dormir compta"))
        #expect(frase.contains("700"))
    }

    @Test func resumMensualIncloElSon() throws {
        var d = Ajudants.dia("2026-11-02")
        d.sonMinuts = 480
        var e = Ajudants.dia("2026-11-03")
        e.sonMinuts = 420
        let r = Analisi.perMes([d, e], mesos: 1, ara: Ajudants.data("2026-11-15"))
        #expect(try #require(r.first?.sonMitjaHores) == 7.5)
    }
}
