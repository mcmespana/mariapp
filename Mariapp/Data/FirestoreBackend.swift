import Foundation
import FirebaseFirestore

/// Dades al núvol: llars/{llarId}/{col·lecció}/{document}.
/// Firestore guarda una còpia local, així funciona sense connexió i sincronitza quan pot.
final class FirestoreBackend: SyncBackend {
    let esNuvol = true
    let llarId: String
    private let db = Firestore.firestore()

    init(llarId: String) {
        self.llarId = llarId
    }

    private func ref(_ colleccio: String) -> CollectionReference {
        db.collection("llars").document(llarId).collection(colleccio)
    }

    private final class Token: Escolta {
        let registre: ListenerRegistration
        init(_ registre: ListenerRegistration) { self.registre = registre }
        func atura() { registre.remove() }
    }

    func escolta(_ colleccio: String, _ canvi: @escaping ([String: [String: Any]]) -> Void) -> Escolta {
        let registre = ref(colleccio).addSnapshotListener { snapshot, error in
            if let error { print("⚠️ Firestore \(colleccio): \(error.localizedDescription)") }
            guard let snapshot else { return }
            var resultat: [String: [String: Any]] = [:]
            for doc in snapshot.documents {
                resultat[doc.documentID] = Self.netejaTipus(doc.data())
            }
            canvi(resultat)
        }
        return Token(registre)
    }

    func desa(_ colleccio: String, id: String, dades: [String: Any]) {
        ref(colleccio).document(id).setData(dades)
    }

    func fusiona(_ colleccio: String, id: String, camps: [String: OpCamp]) {
        var dades: [String: Any] = [:]
        for (camp, op) in camps {
            switch op {
            case .posa(let valor): dades[camp] = valor ?? FieldValue.delete()
            case .suma(let n): dades[camp] = FieldValue.increment(Int64(n))
            }
        }
        ref(colleccio).document(id).setData(dades, merge: true)
    }

    func esborra(_ colleccio: String, id: String) {
        ref(colleccio).document(id).delete()
    }

    /// Converteix tipus propis de Firestore (Timestamp…) a tipus JSON.
    private static func netejaTipus(_ valor: [String: Any]) -> [String: Any] {
        valor.mapValues(neteja)
    }

    private static func neteja(_ valor: Any) -> Any {
        switch valor {
        case let t as Timestamp: return t.dateValue().timeIntervalSince1970
        case let d as [String: Any]: return d.mapValues(neteja)
        case let a as [Any]: return a.map(neteja)
        case is NSNull: return NSNull()
        default: return valor
        }
    }
}
