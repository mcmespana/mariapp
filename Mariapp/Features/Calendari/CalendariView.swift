import SwiftUI

// TODO(Sonnet): veure docs/plans/03-calendari.md
struct CalendariView: View {
    var body: some View {
        EnConstruccio(
            emoji: "📆",
            titol: "Calendari compartit",
            text: "Ací veuràs el calendari de Google que compartiu, amb emojis, colors i de qui és cada cosa.",
            color: Paleta.blau
        )
        .navigationTitle("Calendari")
    }
}
