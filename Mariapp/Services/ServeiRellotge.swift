#if os(iOS)
import Foundation
import WatchConnectivity

/// Pont amb l'Apple Watch (WatchConnectivity). El rellotge no té Firebase: parla amb l'iPhone.
/// - iPhone → rellotge: `updateApplicationContext` amb un `EstatRellotge` (sempre l'últim).
/// - rellotge → iPhone: `transferUserInfo` amb una `AccioPendent` (arriba encara que l'app estiga tancada).
///   Si el rellotge també ha fet `sendMessage` (immediat), la mateixa acció pot arribar dos voltes: l'id la deduplica.
final class ServeiRellotge: NSObject, WCSessionDelegate {
    static let shared = ServeiRellotge()

    private var sessio: WCSession? { WCSession.isSupported() ? WCSession.default : nil }
    private var tascaEnviament: Task<Void, Never>?
    private let defaults = UserDefaults.standard
    private static let clauProcessades = "rellotge.accions.processades"

    func activa() {
        guard let sessio else { return }
        sessio.delegate = self
        sessio.activate()
    }

    // MARK: iPhone → rellotge

    /// Envia l'estat al rellotge uns instants després de l'últim canvi (no a cada toc).
    func programaEnviament() {
        guard let sessio, sessio.activationState == .activated else { return }
        tascaEnviament?.cancel()
        tascaEnviament = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }
            self?.enviaEstat()
        }
    }

    @MainActor
    private func enviaEstat() {
        guard let sessio, sessio.activationState == .activated, sessio.isPaired, sessio.isWatchAppInstalled else { return }
        let store = DataStore.shared
        var estat = EstatRellotge(
            hui: HuiSnapshot.carrega(),
            cita: CitaSnapshot.carrega(),
            menuAvui: MenuSnapshot.carrega().per(Date()),
            escalaCansament: store.config.escalaCansament
        )
        estat.hui.escalaCansament = store.config.escalaCansament
        guard let dades = try? JSONEncoder().encode(estat) else { return }
        try? sessio.updateApplicationContext(["estat": dades])
    }

    // MARK: rellotge → iPhone

    private func rep(_ dades: Data) {
        guard let pendent = try? JSONDecoder().decode(AccioPendent.self, from: dades) else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.jaProcessada(pendent.id) else { return }
            DataStore.shared.processa([pendent])
            // L'iPhone també actualitza els seus widgets i l'activitat en directe.
            Task { await AccionsRapides.refresca(HuiSnapshot.carrega()) }
        }
    }

    private func jaProcessada(_ id: UUID) -> Bool {
        var vistes = defaults.stringArray(forKey: Self.clauProcessades) ?? []
        if vistes.contains(id.uuidString) { return true }
        vistes.append(id.uuidString)
        defaults.set(Array(vistes.suffix(200)), forKey: Self.clauProcessades)
        return false
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated { programaEnviament() }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // En canviar de rellotge cal tornar a activar la sessió.
        session.activate()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        if session.isWatchAppInstalled { programaEnviament() }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        if let dades = userInfo["accio"] as? Data { rep(dades) }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let dades = message["accio"] as? Data { rep(dades) }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        if let dades = message["accio"] as? Data { rep(dades) }
        replyHandler(["ok": true])
    }
}
#endif
