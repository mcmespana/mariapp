#if os(iOS)
import Foundation
import HealthKit
import Observation

/// Apple Salut (només iPhone, només el dispositiu de la Maria):
/// - el gimnàs s'apunta sol amb els entrenaments (Apple Watch),
/// - l'aigua que s'apunta a Mariapp arriba a Salut,
/// - es llig el son per a creuar-lo amb el cansament.
/// Mai s'escriu `gimnas = false`: si la Maria diu que no, mana ella.
@Observable
final class ServeiSalut {
    static let shared = ServeiSalut()

    private let salut = HKHealthStore()
    @ObservationIgnored private var tascaAigua: Task<Void, Never>?
    @ObservationIgnored private var darreraAiguaAvui: Int?
    @ObservationIgnored private let defaults = UserDefaults.standard

    private static let clauConnectat = "salut.connectat"

    private var store: DataStore { DataStore.shared }
    private var prefs: Preferencies { Preferencies.shared }

    var disponible: Bool { HKHealthStore.isHealthDataAvailable() }

    /// La Maria ja ha passat per "Connectar amb Salut".
    var connectat: Bool {
        get { defaults.bool(forKey: Self.clauConnectat) }
        set { defaults.set(newValue, forKey: Self.clauConnectat) }
    }

    /// Només la Maria, a l'iPhone, amb Salut disponible i connectat.
    private var actiu: Bool { prefs.esMaria && disponible && connectat }

    // MARK: Permisos

    private var tipusLectura: Set<HKObjectType> {
        [HKObjectType.workoutType(), HKCategoryType(.sleepAnalysis)]
    }

    private var tipusEscriptura: Set<HKSampleType> {
        [HKQuantityType(.dietaryWater)]
    }

    /// Demana permís de lectura (entrenaments i son) i d'escriptura (aigua). Torna `true` si el diàleg s'ha pogut mostrar.
    @discardableResult
    func demanaPermis() async -> Bool {
        guard disponible else { return false }
        do {
            try await salut.requestAuthorization(toShare: tipusEscriptura, read: tipusLectura)
            connectat = true
            return true
        } catch {
            return false
        }
    }

    private var potEscriureAigua: Bool {
        salut.authorizationStatus(for: HKQuantityType(.dietaryWater)) == .sharingAuthorized
    }

    // MARK: Tot en tornar a primer pla

    /// Gimnàs (avui i els 7 dies anteriors), aigua (avui i ahir) i son (les dues últimes nits), segons les preferències.
    func sincronitzaTot() async {
        guard actiu else { return }
        await esperaDades()
        if prefs.salutGimnas { await sincronitzaGimnas() }
        if prefs.salutAigua {
            let cal = Calendar.current
            await sincronitzaAigua(dia: ClauDia.avui)
            if let ahir = cal.date(byAdding: .day, value: -1, to: Date()) { await sincronitzaAigua(dia: ClauDia.de(ahir)) }
        }
        if prefs.salutSon { await sincronitzaSon() }
    }

    /// Un moment perquè arriben els dies des del núvol abans de decidir res.
    private func esperaDades() async {
        var intents = 0
        while !store.dies.carregada, intents < 10 {
            try? await Task.sleep(nanoseconds: 500_000_000)
            intents += 1
        }
    }

    // MARK: Gimnàs

    /// Entrenaments d'un dia d'almenys 15 minuts, el més llarg primer.
    func entrenamentsDe(dia: Date) async -> [HKWorkout] {
        let cal = Calendar.current
        let inici = cal.startOfDay(for: dia)
        guard let fi = cal.date(byAdding: .day, value: 1, to: inici) else { return [] }
        let predicat = HKQuery.predicateForSamples(withStart: inici, end: fi, options: .strictStartDate)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout(predicat)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)]
        )
        let tots = (try? await descriptor.result(for: salut)) ?? []
        return tots
            .filter { $0.duration >= 15 * 60 }
            .sorted { $0.duration > $1.duration }
    }

    func sincronitzaGimnas() async {
        let cal = Calendar.current
        for enrere in 0...7 {
            guard let data = cal.date(byAdding: .day, value: -enrere, to: Date()) else { continue }
            guard let millor = await entrenamentsDe(dia: data).first else { continue }
            let clau = ClauDia.de(data)
            let dia = store.dia(clau)
            // Si ja l'hem apuntat una volta, no hi tornem: si la Maria el desmarca, mana ella.
            guard dia.entrenament == nil else { continue }
            let text = CalculSon.textEntrenament(nom: Self.nom(millor.workoutActivityType), minuts: Int((millor.duration / 60).rounded()))
            store.posa(.entrenament, text, dia: clau)
            if !dia.gimnas { store.posa(.gimnas, true, dia: clau) }
        }
    }

    static func nom(_ tipus: HKWorkoutActivityType) -> String {
        switch tipus {
        case .traditionalStrengthTraining: "Força tradicional"
        case .functionalStrengthTraining: "Força funcional"
        case .coreTraining: "Abdominals"
        case .highIntensityIntervalTraining: "HIIT"
        case .running: "Córrer"
        case .walking: "Caminar"
        case .hiking: "Excursió"
        case .cycling: "Bicicleta"
        case .swimming: "Natació"
        case .yoga: "Ioga"
        case .pilates: "Pilates"
        case .elliptical: "El·líptica"
        case .rowing: "Rem"
        case .cardioDance, .socialDance: "Ball"
        case .stairClimbing: "Escales"
        case .flexibility: "Estiraments"
        default: "Entrenament"
        }
    }

    // MARK: Aigua → Salut

    /// Cridada quan canvia l'aigua d'avui (des del `DataStore`): espera ~3 s a què es calme i sincronitza.
    func aiguaPotHaCanviat() {
        guard actiu, prefs.salutAigua else { return }
        let ara = store.avui.aiguaMl
        guard ara != darreraAiguaAvui else { return }
        darreraAiguaAvui = ara
        tascaAigua?.cancel()
        tascaAigua = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            await self?.sincronitzaAigua(dia: ClauDia.avui)
        }
    }

    /// Idempotent: esborra les mostres d'aigua D'ESTA APP d'eixe dia i en escriu UNA amb el total.
    /// Així el desfer, els canvis des d'altres dispositius i les repeticions no dupliquen res.
    func sincronitzaAigua(dia clau: String) async {
        guard actiu, potEscriureAigua, let data = ClauDia.data(clau) else { return }
        let cal = Calendar.current
        let inici = cal.startOfDay(for: data)
        guard let fi = cal.date(byAdding: .day, value: 1, to: inici) else { return }
        let tipus = HKQuantityType(.dietaryWater)

        let delDia = HKQuery.predicateForSamples(withStart: inici, end: fi, options: .strictStartDate)
        let nostres = HKQuery.predicateForObjects(from: HKSource.default())
        let predicat = NSCompoundPredicate(andPredicateWithSubpredicates: [delDia, nostres])
        do {
            _ = try await salut.deleteObjects(of: tipus, predicate: predicat)
            let total = store.dia(clau).aiguaMl
            guard total > 0 else { return }
            // Avui, ara mateix; els dies passats, a migdia.
            let quan = cal.isDateInToday(data) ? Date() : (cal.date(byAdding: .hour, value: 12, to: inici) ?? inici)
            let mostra = HKQuantitySample(
                type: tipus,
                quantity: HKQuantity(unit: .literUnit(with: .milli), doubleValue: Double(total)),
                start: quan,
                end: quan
            )
            try await salut.save(mostra)
        } catch {
            print("⚠️ Salut (aigua): \(error)")
        }
    }

    // MARK: Son

    /// Minuts dormits la nit que acaba en `nit` (de les 18:00 del dia abans a les 12:00). nil si Salut no en té.
    func sonDe(nit: Date) async -> Int? {
        let finestra = CalculSon.finestra(nit: nit)
        let predicat = HKQuery.predicateForSamples(withStart: finestra.inici, end: finestra.fi, options: [])
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: HKCategoryType(.sleepAnalysis), predicate: predicat)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )
        guard let mostres = try? await descriptor.result(for: salut), !mostres.isEmpty else { return nil }
        let intervals = mostres.map { m in
            IntervalSon(inici: m.startDate, fi: m.endDate, dormit: Self.esDormit(m.value))
        }
        let minuts = CalculSon.minutsDormits(intervals, finestra: finestra)
        return minuts > 0 ? minuts : nil
    }

    private static func esDormit(_ valor: Int) -> Bool {
        switch HKCategoryValueSleepAnalysis(rawValue: valor) {
        case .asleepCore, .asleepDeep, .asleepREM, .asleepUnspecified: true
        default: false
        }
    }

    /// Les dues últimes nits. Es guarda si no n'hi havia o si ara n'hi ha més (el Watch sincronitza a poc a poc).
    func sincronitzaSon() async {
        let cal = Calendar.current
        for enrere in 0...1 {
            guard let data = cal.date(byAdding: .day, value: -enrere, to: Date()),
                  let minuts = await sonDe(nit: data) else { continue }
            let clau = ClauDia.de(data)
            if let actual = store.dia(clau).sonMinuts, actual >= minuts { continue }
            store.posa(.sonMinuts, minuts, dia: clau)
        }
    }
}
#endif
