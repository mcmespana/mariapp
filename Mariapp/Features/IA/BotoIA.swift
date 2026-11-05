import SwiftUI

/// Botó "✨ …" que crida la IA. Sense clau, explica com configurar-la en lloc de fallar.
struct BotoIA: View {
    let titol: String
    var color: Color = Paleta.groc
    var carregant = false
    var alAnarAAjustos: (() -> Void)? = nil
    let accio: () -> Void

    @Environment(Navegacio.self) private var nav
    @State private var falta = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                if ServeiIA.configurada {
                    falta = false
                    accio()
                } else {
                    falta = true
                }
            } label: {
                HStack(spacing: 8) {
                    if carregant {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(titol)
                }
            }
            .buttonStyle(.suau(color))
            .disabled(carregant)

            if falta {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Falta la clau de l'API d'Anthropic. Posa-la a Ajustos › Intel·ligència artificial ✨")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(Paleta.tintaSuau)
                    Button("Anar a Ajustos") {
                        alAnarAAjustos?()
                        nav.seccio = .ajustos
                    }
                    .buttonStyle(.suau(color))
                }
                .transition(.opacity)
            }
        }
        .animation(Clay.molla, value: falta)
    }
}

/// Targeta de resultat de la IA: text o error amable, amb shimmer mentre carrega.
struct ResultatIA: View {
    let text: String?
    let error: String?
    let carregant: Bool
    var color: Color = Paleta.groc

    var body: some View {
        if carregant || text != nil || error != nil {
            VStack(alignment: .leading, spacing: 8) {
                if carregant {
                    Text("Pensant… 🤔")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Paleta.tintaSuau)
                } else if let error {
                    Text("⚠️ \(error)")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Paleta.tinta)
                } else if let text {
                    Text(text)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Paleta.tinta)
                        .textSelection(.enabled)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .clay(color, radi: Clay.radiMitja, elevacio: 0.5)
            .shimmer(carregant, radi: Clay.radiMitja)
        }
    }
}

extension Error {
    /// Missatge curt i amable per a mostrar-lo a la Maria.
    var missatgeIA: String {
        (self as? LocalizedError)?.errorDescription ?? localizedDescription
    }
}
