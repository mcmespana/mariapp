import Foundation
import Testing
@testable import Mariapp

struct ResumSetmanalTests {
    /// Setmana del dilluns 2 al diumenge 8 de novembre de 2026.
    private let inici = Setmana.inici(de: Ajudants.data("2026-11-04"))

    private func setmanaDeProva() -> [Dia] {
        [
            Ajudants.dia("2026-11-02", aigua: 2300, cafes: 1, gimnas: true, cansament: 300),
            Ajudants.dia("2026-11-03", aigua: 1200, cafes: 2, queixes: 2, cansament: 700, dolor: 2),
            // dimecres sense apuntar
            Ajudants.dia("2026-11-05", aigua: 2500, gimnas: true, dolor: 0),
            Ajudants.dia("2026-11-06", aigua: 900, cafes: 3, queixes: 1),
            // fora de la setmana: no compta
            Ajudants.dia("2026-11-09", aigua: 5000, gimnas: true),
        ]
    }

    @Test func iniciEsDilluns() {
        #expect(ClauDia.de(inici) == "2026-11-02")
    }

    @Test func calculaTotalsISaltaElsDiesSenseApuntar() {
        let r = ResumSetmanal.calcula(dies: setmanaDeProva(), setmana: inici, objectiuMl: 2250)
        #expect(r.dies.count == 7)
        #expect(r.diesApuntats == 4)
        #expect(r.aiguaTotalMl == 6900)
        #expect(r.diesAmbAigua == 4)
        #expect(r.diesGimnas == 2)
        #expect(r.cafes == 6)
        #expect(r.queixes == 3)
        #expect(r.diesMolesties == 1)
        #expect(r.dies[2].apuntat == false)
    }

    @Test func millorDiaIDiesDObjectiu() throws {
        let r = ResumSetmanal.calcula(dies: setmanaDeProva(), setmana: inici, objectiuMl: 2250)
        let millor = try #require(r.millorDiaAigua)
        #expect(millor.valor == 2500)
        #expect(millor.nomDia == "dijous")
        // 2300 i 2500 arriben a 2250.
        #expect(r.diesObjectiuAigua == 2)
    }

    @Test func cansamentMitjaIDiesExtrems() throws {
        let r = ResumSetmanal.calcula(dies: setmanaDeProva(), setmana: inici, objectiuMl: 2250)
        #expect(r.cansamentMitja == 500)
        #expect(r.diaMesCansat?.valor == 700)
        #expect(r.diaMesCansat?.nomDia == "dimarts")
        #expect(r.diaMenysCansat?.valor == 300)
    }

    @Test func ambUnSolDiDeCansamentNoHiHaExtrems() {
        let dies = [Ajudants.dia("2026-11-02", cansament: 400)]
        let r = ResumSetmanal.calcula(dies: dies, setmana: inici, objectiuMl: 2250)
        #expect(r.cansamentMitja == 400)
        #expect(r.diaMesCansat == nil)
        #expect(r.diaMenysCansat == nil)
    }

    @Test func setmanaBuidaNoTeDades() {
        let r = ResumSetmanal.calcula(dies: [], setmana: inici, objectiuMl: 2250)
        #expect(!r.teDades)
        #expect(r.millorDiaAigua == nil)
        #expect(r.cansamentMitja == nil)
        #expect(r.aiguaMitjanaDia == nil)
    }

    // MARK: Comparativa

    private func setmanaAnterior() -> ResumSetmana {
        let dies = [
            Ajudants.dia("2026-10-26", aigua: 1000, gimnas: true, cansament: 800),
            Ajudants.dia("2026-10-27", aigua: 1100, cansament: 700),
            Ajudants.dia("2026-10-28", aigua: 900, cafes: 1),
            Ajudants.dia("2026-10-29", aigua: 1000, dolor: 2),
        ]
        return ResumSetmanal.calcula(dies: dies, setmana: Setmana.mou(inici, setmanes: -1), objectiuMl: 2250)
    }

    @Test func comparativaAmbSetmanaAnteriorBuidaNoDonaFrases() {
        let actual = ResumSetmanal.calcula(dies: setmanaDeProva(), setmana: inici, objectiuMl: 2250)
        let buida = ResumSetmanal.calcula(dies: [], setmana: Setmana.mou(inici, setmanes: -1), objectiuMl: 2250)
        let ara = Ajudants.data("2026-11-10")
        #expect(ResumSetmanal.comparativa(actual: actual, anterior: buida, ara: ara).isEmpty)
        #expect(ResumSetmanal.comparativa(actual: buida, anterior: actual, ara: ara).isEmpty)
    }

    @Test func comparativaDiuMesAiguaMenysCansamentIMenysMolesties() {
        let actual = ResumSetmanal.calcula(dies: setmanaDeProva(), setmana: inici, objectiuMl: 2250)
        let frases = ResumSetmanal.comparativa(actual: actual, anterior: setmanaAnterior(), ara: Ajudants.data("2026-11-10"))
        // 1725 ml/dia de mitjana vs 1000.
        #expect(frases.contains { $0.hasPrefix("💧 +") && $0.contains("més al dia") })
        // 500 vs 750 de cansament mitjà (escala 1000): 250 menys.
        #expect(frases.contains { $0.contains("Menys cansada") })
        // Mateix nombre de dies amb molèsties (1 i 1): cap frase de molèsties.
        #expect(!frases.contains { $0.contains("molèsties") })
        // Un dia més de gimnàs? 2 vs 1.
        #expect(frases.contains { $0.contains("1 dia més de gimnàs") })
    }

    @Test func comparativaNoComparaRecomptesDeUnaSetmanaEnCurs() {
        let actual = ResumSetmanal.calcula(dies: setmanaDeProva(), setmana: inici, objectiuMl: 2250)
        // Dimecres: la setmana no ha acabat.
        let frases = ResumSetmanal.comparativa(actual: actual, anterior: setmanaAnterior(), ara: Ajudants.data("2026-11-04"))
        #expect(!frases.contains { $0.contains("gimnàs") })
        #expect(frases.contains { $0.contains("més al dia") })
    }

    // MARK: Notificació

    @Test func textDeLaNotificacioSenseDades() {
        let r = ResumSetmanal.calcula(dies: [], setmana: inici, objectiuMl: 2250)
        #expect(ResumSetmanal.titolNotificacio(r) == "Ja tens el resum de la setmana 📊")
        #expect(ResumSetmanal.cosNotificacio(r) == "Obri'l i mira com t'ha anat")
    }

    @Test func textDeLaNotificacioAmbDadesTeMaximDuesLinies() {
        let r = ResumSetmanal.calcula(dies: setmanaDeProva(), setmana: inici, objectiuMl: 2250)
        let cos = ResumSetmanal.cosNotificacio(r)
        #expect(cos.split(separator: "\n").count <= 2)
        // El millor que es pot dir: el millor dia d'aigua.
        #expect(cos.contains("dijous"))
        #expect(cos.contains("3 queixes sobre David"))
    }

    @Test func notificacioDeCampiona() {
        let dies = (2...6).map { Ajudants.dia("2026-11-0\($0)", aigua: 2400) }
        let r = ResumSetmanal.calcula(dies: dies, setmana: inici, objectiuMl: 2250)
        #expect(r.diesObjectiuAigua == 5)
        #expect(ResumSetmanal.cosNotificacio(r).contains("Campiona"))
    }

    @Test func queixaSingular() {
        let r = ResumSetmanal.calcula(dies: [Ajudants.dia("2026-11-02", queixes: 1)], setmana: inici, objectiuMl: 2250)
        #expect(ResumSetmanal.cosNotificacio(r).contains("1 queixa sobre David"))
    }

    @Test func notificacioEsProgramaPelProximDiumenge() throws {
        // Dimecres 4 de novembre → diumenge 8 a les 21:00.
        let dimecres = Ajudants.data("2026-11-04")
        let quan = try #require(ResumSetmanal.dataNotificacio(ara: dimecres, hora: Hora(hora: 21, minut: 0)))
        #expect(ClauDia.de(quan) == "2026-11-08")
        #expect(Calendar.current.component(.hour, from: quan) == 21)
        #expect(Setmana.numeroDia(quan) == 7)
    }

    @Test func siJaHaPassatLHoraDelDiumengeVaAlSeguent() throws {
        let diumengeNit = Ajudants.data("2026-11-08").addingTimeInterval(10 * 3600) // 22:00
        let quan = try #require(ResumSetmanal.dataNotificacio(ara: diumengeNit, hora: Hora(hora: 21, minut: 0)))
        #expect(ClauDia.de(quan) == "2026-11-15")
    }

    @Test func setmanaPerDefecte() {
        // Dimecres → la setmana passada (acabada); diumenge → l'actual.
        #expect(ClauDia.de(ResumSetmanal.setmanaPerDefecte(ara: Ajudants.data("2026-11-04"))) == "2026-10-26")
        #expect(ClauDia.de(ResumSetmanal.setmanaPerDefecte(ara: Ajudants.data("2026-11-08"))) == "2026-11-02")
    }
}
