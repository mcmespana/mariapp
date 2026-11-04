import Foundation
import Security

/// Guarda secrets (com la clau de l'API d'IA) al Clauer del sistema.
enum Clauer {
    static func desa(_ valor: String?, clau: String) {
        let consulta: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: clau,
        ]
        SecItemDelete(consulta as CFDictionary)
        guard let valor, !valor.isEmpty else { return }
        var nou = consulta
        nou[kSecValueData as String] = Data(valor.utf8)
        SecItemAdd(nou as CFDictionary, nil)
    }

    static func llig(_ clau: String) -> String? {
        let consulta: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: clau,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var resultat: AnyObject?
        guard SecItemCopyMatching(consulta as CFDictionary, &resultat) == errSecSuccess,
              let data = resultat as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
