import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Punt únic per a executar una acció ràpida des de qualsevol lloc.
/// - Actualitza la foto local (widgets / Live Activity) a l'instant.
/// - Deixa l'acció a la cua i, si estem dins de l'app, l'app la puja al núvol de seguida.
enum AccionsRapides {
    /// L'app registra ací el seu processador en arrancar. A l'extensió de widgets és nil.
    static var processador: (@MainActor ([AccioPendent]) -> Void)?

    static func executa(_ accio: AccioRapida) async {
        var snap = HuiSnapshot.carrega()
        switch accio {
        case .aigua(let ml): snap.aiguaMl = max(0, snap.aiguaMl + ml)
        case .cafe(let n): snap.cafes = max(0, snap.cafes + n)
        case .queixa: snap.queixes += 1
        case .cansament(let valor): snap.cansament = max(0, valor)
        case .comprat(let id):
            // El widget de la compra el treu de la llista a l'instant; l'app el marcarà de veres al núvol.
            var compra = CompraSnapshot.carrega()
            compra.treu(id: id)
            compra.desa()
        }
        snap.desa()
        CuaAccions.afegeix(AccioPendent(dia: snap.dia, accio: accio, data: Date()))

        if let processador {
            await MainActor.run { processador(CuaAccions.buida()) }
        }
        await refresca(snap)
    }

    static func refresca(_ snap: HuiSnapshot) async {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
        #if os(iOS)
        await ActivitatHui.actualitza(snap)
        #endif
    }
}
