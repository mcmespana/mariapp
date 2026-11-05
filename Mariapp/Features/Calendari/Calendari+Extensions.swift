import SwiftUI

extension ColorEtiqueta {
    var color: Color {
        switch self {
        case .aigua: Paleta.aigua
        case .blau: Paleta.blau
        case .verd: Paleta.verd
        case .groc: Paleta.groc
        case .taronja: Paleta.taronja
        case .cafe: Paleta.cafe
        }
    }

    var nom: String {
        switch self {
        case .aigua: "Turquesa"
        case .blau: "Blau"
        case .verd: "Verd"
        case .groc: "Groc"
        case .taronja: "Taronja"
        case .cafe: "Cafè"
        }
    }
}

extension Propietari {
    var color: Color {
        switch self {
        case .maria: Paleta.groc
        case .david: Paleta.blau
        case .tots: Paleta.taronja
        }
    }
}

/// Avisos extra que es poden triar per a un esdeveniment (minuts abans).
enum AvisosAnotacio {
    static let opcions = [10, 30, 60, 120, 1440, 2880]

    static func nom(_ m: Int) -> String {
        switch m {
        case ..<60: "\(m) min"
        case 60: "1 hora"
        case ..<1440: "\(m / 60) hores"
        case 1440: "1 dia"
        default: "\(m / 1440) dies"
        }
    }
}

/// Reprograma els avisos extra dels esdeveniments pròxims (dispositiu de la Maria).
enum ServeiAnotacions {
    static func reprograma() {
        guard Preferencies.shared.esMaria else { return }
        let calendari = ServeiCalendari.shared
        guard calendari.autoritzat else { return }
        let limit = Date().addingTimeInterval(30 * 86400)
        for e in calendari.esdeveniments where e.startDate < limit && e.startDate > Date() {
            let clau = ServeiCalendari.clau(per: e)
            if let a = DataStore.shared.anotacions[clau], !a.avisos.isEmpty {
                Avisos.programa(anotacio: a, titol: e.title ?? "Esdeveniment", inici: e.startDate)
            }
        }
    }
}
