#if os(iOS)
import ActivityKit
import Foundation

struct HuiActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var aiguaMl: Int
        var objectiuMl: Int
        var ampollaMl: Int
        var cafes: Int
        var queixes: Int

        init(_ snap: HuiSnapshot) {
            aiguaMl = snap.aiguaMl
            objectiuMl = snap.objectiuMl
            ampollaMl = snap.ampollaMl
            cafes = snap.cafes
            queixes = snap.queixes
        }

        var progres: Double {
            guard objectiuMl > 0 else { return 0 }
            return min(Double(aiguaMl) / Double(objectiuMl), 1)
        }
    }

    var dia: String
}

/// Gestiona l'activitat en directe "Hui" (pantalla de bloqueig + Dynamic Island).
enum ActivitatHui {
    static var activa: Bool {
        !Activity<HuiActivityAttributes>.activities.isEmpty
    }

    static func comenca(_ snap: HuiSnapshot) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        // Si ja n'hi ha una d'un altre dia, la tanquem.
        for activitat in Activity<HuiActivityAttributes>.activities where activitat.attributes.dia != snap.dia {
            Task { await activitat.end(nil, dismissalPolicy: .immediate) }
        }
        guard !Activity<HuiActivityAttributes>.activities.contains(where: { $0.attributes.dia == snap.dia }) else { return }
        let contingut = ActivityContent(state: HuiActivityAttributes.ContentState(snap), staleDate: nil)
        _ = try? Activity.request(attributes: HuiActivityAttributes(dia: snap.dia), content: contingut, pushType: nil)
    }

    static func actualitza(_ snap: HuiSnapshot) async {
        let contingut = ActivityContent(state: HuiActivityAttributes.ContentState(snap), staleDate: nil)
        for activitat in Activity<HuiActivityAttributes>.activities {
            await activitat.update(contingut)
        }
    }

    static func acaba() async {
        for activitat in Activity<HuiActivityAttributes>.activities {
            await activitat.end(nil, dismissalPolicy: .immediate)
        }
    }
}
#endif
