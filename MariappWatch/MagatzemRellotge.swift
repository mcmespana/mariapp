import Foundation
import SwiftUI
import Observation
import WatchConnectivity
import WatchKit
import WidgetKit

/// L'estat del rellotge. L'iPhone li'l envia (WatchConnectivity) i les accions del rellotge s'apliquen
/// aquí a l'instant (optimista) i viatgen cap a l'iPhone, que les puja a Firestore.
@Observable
final class MagatzemRellotge: NSObject, WCSessionDelegate {
    static let shared = MagatzemRellotge()

    var estat: EstatRellotge
    /// Accions fetes abans que la sessió estiga activa; s'envien en activar-se.
    @ObservationIgnored private var enEspera: [Data] = []

    override init() {
        estat = EstatRellotge.carrega()
        super.init()
    }

    func activa() {
        guard WCSession.isSupported() else { return }
        let sessio = WCSession.default
        sessio.delegate = self
        sessio.activate()
    }

    /// En tornar a primer pla: si ha canviat el dia, tot a zero; i recarrega les complicacions.
    func refresca() {
        let nou = estat.normalitzat()
        if nou != estat { estat = nou }
        estat.desa()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: Accions

    func envia(_ accio: AccioRapida) {
        estat = estat.normalitzat()
        estat.aplica(accio)
        estat.desa()
        WidgetCenter.shared.reloadAllTimelines()

        let pendent = AccioPendent(dia: estat.hui.dia, accio: accio, data: Date())
        guard let dades = try? JSONEncoder().encode(pendent) else { return }
        enviaADispositiu(dades)
    }

    private func enviaADispositiu(_ dades: Data) {
        guard WCSession.isSupported() else { return }
        let sessio = WCSession.default
        guard sessio.activationState == .activated else {
            enEspera.append(dades)
            return
        }
        // transferUserInfo arriba sempre (encara que l'iPhone estiga bloquejat o lluny).
        sessio.transferUserInfo(["accio": dades])
        // Si l'iPhone està a l'abast, a més, un missatge immediat (l'iPhone deduplica pel mateix id).
        if sessio.isReachable {
            sessio.sendMessage(["accio": dades], replyHandler: nil, errorHandler: nil)
        }
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard activationState == .activated else { return }
        DispatchQueue.main.async { [self] in
            let pendents = enEspera
            enEspera = []
            pendents.forEach { enviaADispositiu($0) }
            // L'últim estat que l'iPhone ens va enviar, per si va arribar amb l'app tancada.
            if let dades = session.receivedApplicationContext["estat"] as? Data { rep(dades) }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let dades = applicationContext["estat"] as? Data { rep(dades) }
    }

    private func rep(_ dades: Data) {
        guard let nou = try? JSONDecoder().decode(EstatRellotge.self, from: dades) else { return }
        DispatchQueue.main.async { [self] in
            withAnimation(.smooth) { estat = nou.normalitzat() }
            estat.desa()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
