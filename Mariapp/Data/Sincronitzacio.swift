import Foundation
import Observation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

/// Gestiona on es guarden les dades: només en aquest dispositiu, o al núvol en una "llar" compartida.
///
/// Cada dispositiu entra a Firebase de manera anònima (sense comptes ni contrasenyes).
/// La llar té un codi; qui té el codi s'hi pot unir (el mòbil de Maria, el seu Mac, David…).
@Observable
final class Sincronitzacio {
    static let shared = Sincronitzacio()

    enum Estat: Equatable {
        case local
        case connectant
        case connectat(codi: String)
        case error(String)
    }

    private(set) var estat: Estat = .local
    @ObservationIgnored private var configurat = false

    private static let clauLlar = "sync.llarId"

    /// Hi ha `GoogleService-Info.plist` a l'app? Sense ell, tot funciona però només en local.
    static var firebaseDisponible: Bool {
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }

    var codiLlar: String? {
        UserDefaults.standard.string(forKey: Self.clauLlar)
    }

    /// Cridar en arrancar l'app (també en segon pla).
    func arranca() {
        guard Self.firebaseDisponible else { estat = .local; return }
        configuraFirebase()
        if let codi = codiLlar {
            DataStore.shared.connecta(FirestoreBackend(llarId: codi))
            estat = .connectat(codi: codi)
            Task { try? await asseguraSessio() }
        }
    }

    private func configuraFirebase() {
        guard !configurat else { return }
        if FirebaseApp.app() == nil { FirebaseApp.configure() }
        configurat = true
    }

    @discardableResult
    private func asseguraSessio() async throws -> String {
        if let usuari = Auth.auth().currentUser { return usuari.uid }
        let resultat = try await Auth.auth().signInAnonymously()
        return resultat.user.uid
    }

    /// Crea una llar nova al núvol i hi puja tot el que hi haja en local.
    @MainActor
    func creaLlar() async {
        guard Self.firebaseDisponible else { return }
        configuraFirebase()
        estat = .connectant
        do {
            let uid = try await asseguraSessio()
            let codi = Self.nouCodi()
            let db = Firestore.firestore()
            try await db.collection("llars").document(codi).setData([
                "membres": [uid],
                "creada": FieldValue.serverTimestamp(),
            ])
            // Pugem les dades locals.
            let backend = FirestoreBackend(llarId: codi)
            for (colleccio, docs) in LocalBackend.shared.totes() {
                for (id, dades) in docs {
                    backend.desa(colleccio, id: id, dades: dades)
                }
            }
            UserDefaults.standard.set(codi, forKey: Self.clauLlar)
            DataStore.shared.connecta(backend)
            estat = .connectat(codi: codi)
        } catch {
            estat = .error("No s'ha pogut crear la llar: \(error.localizedDescription)")
        }
    }

    /// S'uneix a una llar existent amb el seu codi.
    @MainActor
    func uneix(codi brut: String) async {
        guard Self.firebaseDisponible else { return }
        configuraFirebase()
        let codi = Self.normalitza(brut)
        guard !codi.isEmpty else { return }
        estat = .connectant
        do {
            let uid = try await asseguraSessio()
            let ref = Firestore.firestore().collection("llars").document(codi)
            try await ref.updateData(["membres": FieldValue.arrayUnion([uid])])
            UserDefaults.standard.set(codi, forKey: Self.clauLlar)
            DataStore.shared.connecta(FirestoreBackend(llarId: codi))
            estat = .connectat(codi: codi)
        } catch {
            estat = .error("Eixe codi no funciona. Revisa'l i torna-ho a provar.")
        }
    }

    /// Torna a mode local (les dades del núvol no s'esborren).
    func desconnecta() {
        UserDefaults.standard.removeObject(forKey: Self.clauLlar)
        DataStore.shared.connecta(LocalBackend.shared)
        estat = .local
    }

    func enllacInvitacio(_ codi: String) -> URL {
        URL(string: "mariapp://unir?codi=\(codi)")!
    }

    // MARK: Codis

    private static let alfabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    static func nouCodi() -> String {
        let lletres = (0..<10).map { _ in String(alfabet.randomElement()!) }.joined()
        return "MARI" + lletres
    }

    static func normalitza(_ codi: String) -> String {
        codi.uppercased().filter { $0.isLetter || $0.isNumber }
    }
}
