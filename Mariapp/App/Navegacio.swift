import SwiftUI
import Observation

enum Seccio: String, CaseIterable, Identifiable, Hashable {
    case hui, calendari, menu, metges, compra, estadistiques, david, fills, ajustos

    var id: String { rawValue }

    var nom: String {
        switch self {
        case .hui: "Hui"
        case .calendari: "Calendari"
        case .menu: "Menú"
        case .metges: "Metges"
        case .compra: "Compra"
        case .estadistiques: "Estadístiques"
        case .david: "David"
        case .fills: NomFills.dHui
        case .ajustos: "Ajustos"
        }
    }

    var icona: String {
        switch self {
        case .hui: "sun.max.fill"
        case .calendari: "calendar"
        case .menu: "fork.knife"
        case .metges: "cross.case.fill"
        case .compra: "cart.fill"
        case .estadistiques: "chart.bar.xaxis"
        case .david: "heart.text.square.fill"
        case .fills: "sparkles"
        case .ajustos: "gearshape.fill"
        }
    }

    var color: Color {
        switch self {
        case .hui: Paleta.groc
        case .calendari: Paleta.blau
        case .menu: Paleta.verd
        case .metges: Paleta.alerta
        case .compra: Paleta.verd
        case .estadistiques: Paleta.aigua
        case .david: Paleta.taronja
        case .fills: Paleta.groc
        case .ajustos: Paleta.tintaSuau
        }
    }

    /// Les que van a la barra de pestanyes de l'iPhone. La resta, a "Més".
    static let principals: [Seccio] = [.hui, .calendari, .menu, .metges]
    static let secundaries: [Seccio] = [.compra, .estadistiques, .david, .fills, .ajustos]
}

/// El nom de la secció de fills canvia cada dia. Perquè sí.
enum NomFills {
    static let noms = ["Fills", "Filles", "Fillis", "Filletes", "Fillets", "Fillus"]

    static var dHui: String {
        let dia = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return noms[dia % noms.count]
    }
}

@Observable
final class Navegacio {
    static let shared = Navegacio()

    var seccio: Seccio = .hui
    var mostraCansament = false
    var codiInvitacio: String?

    func obri(_ url: URL) {
        guard url.scheme == "mariapp" else { return }
        switch url.host {
        case "unir":
            let codi = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "codi" }?.value
            codiInvitacio = codi
            seccio = .ajustos
        case "cansament":
            seccio = .hui
            mostraCansament = true
        case let host?:
            if let s = Seccio(rawValue: host) { seccio = s }
        default:
            break
        }
    }
}
