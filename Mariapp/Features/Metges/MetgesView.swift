import SwiftUI

// TODO(Sonnet): veure docs/plans/02-metges.md
struct MetgesView: View {
    var body: some View {
        EnConstruccio(
            emoji: "🚨",
            titol: "METGES",
            text: "Cites, cites per demanar i avisos EXAGERATS perquè no se t'oblide res. Ací sí que tot en roig.",
            color: Paleta.alerta
        )
        .navigationTitle("Metges")
    }
}
