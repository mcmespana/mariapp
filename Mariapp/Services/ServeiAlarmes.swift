import Foundation
import SwiftUI
#if os(iOS)
import AlarmKit
import AppIntents

struct MetadadesAlarma: AlarmMetadata {}

/// Botó secundari de l'alarma: obri l'app a Metges.
struct JaVaigIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Ja vaig!"
    static let openAppWhenRun = true

    init() {}

    func perform() async throws -> some IntentResult {
        await MainActor.run { Navegacio.shared.seccio = .metges }
        return .result()
    }
}
#endif

/// Alarmes de despertador de veritat (AlarmKit, iOS 26+) per a les cites del metge.
/// Sonen encara que el mòbil estiga en silenci. En Mac no fan res.
enum ServeiAlarmes {
    #if os(iOS)
    static func demanaPermis() async -> Bool {
        switch AlarmManager.shared.authorizationState {
        case .authorized: return true
        case .denied: return false
        default:
            return ((try? await AlarmManager.shared.requestAuthorization()) ?? .denied) == .authorized
        }
    }

    /// Programa l'alarma d'una cita. Torna l'identificador (o nil si no s'ha pogut / no cal).
    static func programa(cita: Cita) async -> String? {
        guard Preferencies.shared.esMaria,
              cita.estat == .programada,
              let data = cita.data,
              let minuts = cita.alarmaMinuts else { return nil }
        let quan = data.addingTimeInterval(TimeInterval(-minuts * 60))
        guard quan > Date(), await demanaPermis() else { return nil }

        let alerta = AlarmPresentation.Alert(
            title: "🚨 \(cita.titol)",
            secondaryButton: AlarmButton(text: "Ja vaig! 🏃‍♀️", textColor: .white, systemImageName: "figure.run"),
            secondaryButtonBehavior: .custom
        )
        let atributs = AlarmAttributes<MetadadesAlarma>(
            presentation: AlarmPresentation(alert: alerta),
            metadata: nil,
            tintColor: Paleta.alerta
        )
        let configuracio = AlarmManager.AlarmConfiguration<MetadadesAlarma>.alarm(
            schedule: .fixed(quan),
            attributes: atributs,
            secondaryIntent: JaVaigIntent(),
            sound: .named("sirena.wav")
        )
        let id = UUID()
        do {
            _ = try await AlarmManager.shared.schedule(id: id, configuration: configuracio)
            return id.uuidString
        } catch {
            print("⚠️ AlarmKit: \(error)")
            return nil
        }
    }

    static func cancela(alarmaId: String?) {
        guard let alarmaId, let id = UUID(uuidString: alarmaId) else { return }
        try? AlarmManager.shared.cancel(id: id)
    }

    /// L'alarma ja existeix al sistema amb la mateixa hora?
    static func esVigent(cita: Cita) -> Bool {
        guard let alarmaId = cita.alarmaId, let id = UUID(uuidString: alarmaId),
              let data = cita.data, let minuts = cita.alarmaMinuts,
              let alarmes = try? AlarmManager.shared.alarms,
              let alarma = alarmes.first(where: { $0.id == id }) else { return false }
        let esperada = data.addingTimeInterval(TimeInterval(-minuts * 60))
        if case .fixed(let quan)? = alarma.schedule {
            return abs(quan.timeIntervalSince(esperada)) < 1
        }
        return false
    }
    #else
    static func demanaPermis() async -> Bool { false }
    static func programa(cita: Cita) async -> String? { nil }
    static func cancela(alarmaId: String?) {}
    static func esVigent(cita: Cita) -> Bool { false }
    #endif
}
