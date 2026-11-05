import CryptoKit
import EventKit
import Foundation
import Observation

/// Accés al calendari del sistema (on hi ha el Google Calendar compartit si està afegit a Ajustos > Calendari).
/// Sense OAuth ni APIs de Google: iOS/macOS ja el sincronitzen.
@Observable
final class ServeiCalendari {
    static let shared = ServeiCalendari()

    @ObservationIgnored let store = EKEventStore()
    private(set) var autoritzat = false
    private(set) var calendaris: [EKCalendar] = []
    private(set) var esdeveniments: [EKEvent] = []

    /// Calendaris que es mostren (ids). Buit = tots.
    var calendarisVisibles: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(calendarisVisibles), forKey: "calendari.visibles")
            recarrega()
        }
    }
    /// Calendari on es creen les cites del metge. nil = el per defecte.
    var calendariCites: String? {
        didSet { UserDefaults.standard.set(calendariCites, forKey: "calendari.cites") }
    }

    private init() {
        calendarisVisibles = Set(UserDefaults.standard.stringArray(forKey: "calendari.visibles") ?? [])
        calendariCites = UserDefaults.standard.string(forKey: "calendari.cites")
        autoritzat = EKEventStore.authorizationStatus(for: .event) == .fullAccess
        NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: store, queue: .main) { [weak self] _ in
            self?.recarrega()
        }
        if autoritzat { recarrega() }
    }

    @discardableResult
    func demanaAcces() async -> Bool {
        let ok = (try? await store.requestFullAccessToEvents()) ?? false
        await MainActor.run {
            autoritzat = ok
            if ok { recarrega() }
        }
        return ok
    }

    func recarrega(dies: Int = 60) {
        guard autoritzat else { return }
        calendaris = store.calendars(for: .event).sorted { $0.title < $1.title }
        let inici = Calendar.current.startOfDay(for: Date())
        let fi = Calendar.current.date(byAdding: .day, value: dies, to: inici) ?? inici
        let seleccionats = calendarisVisibles.isEmpty ? nil : calendaris.filter { calendarisVisibles.contains($0.calendarIdentifier) }
        let predicat = store.predicateForEvents(withStart: inici, end: fi, calendars: seleccionats)
        esdeveniments = store.events(matching: predicat).sorted { $0.startDate < $1.startDate }
    }

    /// Clau estable d'un esdeveniment per a guardar-hi anotacions (igual a tots els dispositius).
    static func clau(per esdeveniment: EKEvent) -> String {
        var base = esdeveniment.calendarItemExternalIdentifier ?? esdeveniment.eventIdentifier ?? UUID().uuidString
        if esdeveniment.hasRecurrenceRules {
            base += "@" + ClauDia.de(esdeveniment.startDate)
        }
        let hash = SHA256.hash(data: Data(base.utf8))
        return hash.prefix(16).map { String(format: "%02x", $0) }.joined()
    }

    /// Crea un esdeveniment nou al calendari triat (o al per defecte).
    func crea(titol: String, inici: Date, durada: TimeInterval = 3600, totElDia: Bool, calendari: EKCalendar?) throws -> EKEvent {
        let e = EKEvent(eventStore: store)
        e.calendar = calendari ?? store.defaultCalendarForNewEvents
        e.title = titol
        e.isAllDay = totElDia
        e.startDate = inici
        e.endDate = totElDia ? inici : inici.addingTimeInterval(durada)
        try store.save(e, span: .thisEvent, commit: true)
        recarrega()
        return e
    }

    // MARK: Cites del metge

    /// Crea o actualitza l'esdeveniment d'una cita. Retorna l'eventIdentifier.
    func sincronitza(cita: Cita, categoria: CategoriaMetge?) throws -> String? {
        guard autoritzat, cita.estat == .programada, let data = cita.data else { return cita.esdevenimentId }
        let esdeveniment: EKEvent
        if let id = cita.esdevenimentId, let existent = store.event(withIdentifier: id) {
            esdeveniment = existent
        } else {
            esdeveniment = EKEvent(eventStore: store)
            esdeveniment.calendar = calendariCites.flatMap { store.calendar(withIdentifier: $0) } ?? store.defaultCalendarForNewEvents
        }
        let emoji = categoria?.emoji ?? "🏥"
        esdeveniment.title = "\(emoji) \(cita.titol)"
        esdeveniment.startDate = data
        esdeveniment.endDate = data.addingTimeInterval(TimeInterval(cita.duradaMinuts * 60))
        esdeveniment.location = cita.lloc.isEmpty ? nil : cita.lloc
        esdeveniment.notes = cita.notes.isEmpty ? nil : cita.notes
        esdeveniment.alarms = cita.avisos.map { EKAlarm(relativeOffset: TimeInterval(-$0 * 60)) }
        try store.save(esdeveniment, span: .thisEvent, commit: true)
        return esdeveniment.eventIdentifier
    }

    func esborra(esdevenimentId: String?) {
        guard autoritzat, let id = esdevenimentId, let e = store.event(withIdentifier: id) else { return }
        try? store.remove(e, span: .thisEvent, commit: true)
    }
}
