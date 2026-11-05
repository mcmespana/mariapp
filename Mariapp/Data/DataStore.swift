import Foundation
import Observation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Una col·lecció de registres que s'actualitza sola quan canvien les dades (local o núvol).
@Observable
final class Coleccio<T: Registre> {
    private(set) var items: [T] = []
    private(set) var perId: [String: T] = [:]
    private(set) var carregada = false

    @ObservationIgnored private var escolta: Escolta?
    @ObservationIgnored private weak var backend: SyncBackend?
    @ObservationIgnored var enCanviar: (() -> Void)?

    func connecta(_ backend: SyncBackend) {
        escolta?.atura()
        self.backend = backend
        carregada = false
        escolta = backend.escolta(T.colleccio) { [weak self] docs in
            self?.aplica(docs)
        }
    }

    private func aplica(_ docs: [String: [String: Any]]) {
        var nous: [String: T] = [:]
        for (id, dades) in docs {
            if let item = Codificador.registre(T.self, id: id, dades: dades) {
                nous[id] = item
            }
        }
        perId = nous
        items = Array(nous.values)
        carregada = true
        enCanviar?()
    }

    subscript(id: String) -> T? { perId[id] }

    func desa(_ item: T) {
        backend?.desa(T.colleccio, id: item.id, dades: Codificador.diccionari(item))
    }

    func esborra(_ item: T) {
        backend?.esborra(T.colleccio, id: item.id)
    }

    func esborra(id: String) {
        backend?.esborra(T.colleccio, id: id)
    }

    func fusiona(id: String, _ camps: [String: OpCamp]) {
        backend?.fusiona(T.colleccio, id: id, camps: camps)
    }
}

/// Totes les dades de la llar. Hi ha una única instància: `DataStore.shared`.
@Observable
final class DataStore {
    static let shared = DataStore()

    let dies = Coleccio<Dia>()
    let configs = Coleccio<Configuracio>()
    let plats = Coleccio<Plat>()
    let menus = Coleccio<MenuSetmana>()
    let categoriesMetge = Coleccio<CategoriaMetge>()
    let cites = Coleccio<Cita>()
    let pensaments = Coleccio<Pensament>()
    let anotacions = Coleccio<AnotacioEsdeveniment>()
    let llistaCompra = Coleccio<ElementCompra>()

    @ObservationIgnored private(set) var backend: SyncBackend = LocalBackend.shared
    @ObservationIgnored private var sembrantPlats = false
    @ObservationIgnored private var citesReprogramades = false
    @ObservationIgnored private var anotacionsReprogramades = false
    @ObservationIgnored private var tascaResum: Task<Void, Never>?

    private init() {
        dies.enCanviar = { [weak self] in
            self?.actualitzaSnapshot()
            self?.reprogramaResumAmbRetard()
        }
        configs.enCanviar = { [weak self] in self?.actualitzaSnapshot() }
        categoriesMetge.enCanviar = { [weak self] in
            self?.sembraCategoriesSiCal()
            self?.actualitzaSnapshotsExtra()
        }
        plats.enCanviar = { [weak self] in
            self?.sembraPlatsSiCal()
            self?.actualitzaSnapshotsExtra()
        }
        menus.enCanviar = { [weak self] in self?.actualitzaSnapshotsExtra() }
        cites.enCanviar = { [weak self] in
            self?.reprogramaCitesLaPrimeraVegada()
            self?.actualitzaSnapshotsExtra()
        }
        anotacions.enCanviar = { [weak self] in self?.reprogramaAnotacionsLaPrimeraVegada() }
        connecta(LocalBackend.shared)
    }

    func connecta(_ backend: SyncBackend) {
        self.backend = backend
        dies.connecta(backend)
        configs.connecta(backend)
        plats.connecta(backend)
        menus.connecta(backend)
        categoriesMetge.connecta(backend)
        cites.connecta(backend)
        pensaments.connecta(backend)
        anotacions.connecta(backend)
        llistaCompra.connecta(backend)
    }

    // MARK: Configuració

    var config: Configuracio { configs[Configuracio.idGeneral] ?? Configuracio() }

    func desaConfig(_ canvi: (inout Configuracio) -> Void) {
        var c = config
        canvi(&c)
        configs.desa(c)
    }

    // MARK: Dies

    func dia(_ clau: String) -> Dia { dies[clau] ?? Dia(id: clau) }
    var avui: Dia { dia(ClauDia.avui) }

    func suma(_ camp: CampDia, _ n: Int, dia: String = ClauDia.avui) {
        dies.fusiona(id: dia, [camp.rawValue: .suma(n)])
    }

    func posa(_ camp: CampDia, _ valor: Any?, dia: String = ClauDia.avui) {
        dies.fusiona(id: dia, [camp.rawValue: .posa(valor)])
    }

    /// Aplica accions fetes fora de l'app (widget, Live Activity, notificacions).
    func processa(_ accions: [AccioPendent]) {
        for a in accions {
            switch a.accio {
            case .aigua(let ml): suma(.aiguaMl, ml, dia: a.dia)
            case .cafe(let n): suma(.cafes, n, dia: a.dia)
            case .queixa: suma(.queixes, 1, dia: a.dia)
            }
        }
    }

    /// Manté al dia la foto que llegeixen widgets i Live Activity.
    private func actualitzaSnapshot() {
        let d = avui
        let c = config
        let pendents = CuaAccions.llegeix().filter { $0.dia == d.id }
        var snap = HuiSnapshot(dia: d.id, aiguaMl: d.aiguaMl, cafes: d.cafes, queixes: d.queixes,
                               gimnas: d.gimnas, objectiuMl: c.objectiuMl, ampollaMl: c.ampollaMl,
                               cansament: d.cansament, escalaCansament: c.escalaCansament)
        // Les accions encara no pujades també compten.
        for p in pendents {
            switch p.accio {
            case .aigua(let ml): snap.aiguaMl += ml
            case .cafe(let n): snap.cafes += n
            case .queixa: snap.queixes += 1
            }
        }
        guard snap != HuiSnapshot.carrega() else { return }
        snap.desa()
        Task { await AccionsRapides.refresca(snap) }
    }

    /// El contingut de la notificació del resum depén dels dies: es recalcula uns segons després
    /// de l'últim canvi (no a cada toc).
    private func reprogramaResumAmbRetard() {
        tascaResum?.cancel()
        tascaResum = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            Avisos.programaResum()
        }
    }

    // MARK: Widgets (pròxima cita i menú de la setmana)

    /// Escriu al App Group la pròxima cita i el menú dels pròxims 7 dies perquè els widgets els pinten.
    private func actualitzaSnapshotsExtra() {
        var canvis = false

        let proxima = ServeiCites.properaCita(cites.items).flatMap { c -> CitaSnapshot? in
            guard let data = c.data else { return nil }
            return CitaSnapshot(titol: c.titol, emoji: categoriesMetge[c.categoriaId]?.emoji ?? "🏥", data: data, lloc: c.lloc)
        }
        if proxima != CitaSnapshot.carrega() {
            CitaSnapshot.desa(proxima)
            canvis = true
        }

        let cal = Calendar.current
        let inici = cal.startOfDay(for: Date())
        var menu = MenuSnapshot()
        for i in 0..<7 {
            guard let dia = cal.date(byAdding: .day, value: i, to: inici) else { continue }
            let setmana = menus[MenuSetmana.id(per: dia)]
            let n = Setmana.numeroDia(dia)
            func text(_ apat: Apat) -> String? {
                guard let e = setmana?.entrada(dia: n, apat: apat) else { return nil }
                if let id = e.platId, let p = plats[id] { return "\(p.emoji) \(p.nom)" }
                return e.text
            }
            let parella = ParellaMenu(dinar: text(.dinar), sopar: text(.sopar))
            if parella.dinar != nil || parella.sopar != nil { menu.dies[ClauDia.de(dia)] = parella }
        }
        if menu != MenuSnapshot.carrega() {
            menu.desa()
            canvis = true
        }

        #if canImport(WidgetKit)
        if canvis { WidgetCenter.shared.reloadAllTimelines() }
        #endif
    }

    // MARK: Menú

    private static let clauPlatsSembrats = "plats.sembrats"

    /// Primer arrancada sense cap plat: sembra uns quants d'exemple (amb id estable, així no es dupliquen entre dispositius).
    /// Espera un moment perquè, si hi ha dades al núvol, arriben abans de decidir que està buit.
    private func sembraPlatsSiCal() {
        let d = UserDefaults.standard
        guard plats.carregada, !d.bool(forKey: Self.clauPlatsSembrats) else { return }
        if !plats.items.isEmpty {
            d.set(true, forKey: Self.clauPlatsSembrats)
            return
        }
        guard !sembrantPlats else { return }
        sembrantPlats = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard let self else { return }
            self.sembrantPlats = false
            guard self.plats.items.isEmpty, !d.bool(forKey: Self.clauPlatsSembrats) else { return }
            d.set(true, forKey: Self.clauPlatsSembrats)
            Plat.exemples.forEach { self.plats.desa($0) }
        }
    }

    // MARK: Calendari

    private func reprogramaAnotacionsLaPrimeraVegada() {
        guard anotacions.carregada, !anotacionsReprogramades else { return }
        anotacionsReprogramades = true
        ServeiAnotacions.reprograma()
    }

    // MARK: Metges

    /// Quan arriben les cites per primera vegada en arrancar, es reprograma tot (avisos i alarmes).
    private func reprogramaCitesLaPrimeraVegada() {
        guard cites.carregada, !citesReprogramades else { return }
        citesReprogramades = true
        ServeiCites.reprograma()
    }

    private func sembraCategoriesSiCal() {
        guard categoriesMetge.carregada, categoriesMetge.items.isEmpty else { return }
        CategoriaMetge.perDefecte.forEach { categoriesMetge.desa($0) }
    }

    var categoriesOrdenades: [CategoriaMetge] {
        categoriesMetge.items.sorted { $0.ordre < $1.ordre }
    }
}
