import SwiftUI

// TODO(Sonnet): veure docs/plans/01-menu-setmanal.md
struct MenuView: View {
    var body: some View {
        EnConstruccio(
            emoji: "🥗",
            titol: "Menú setmanal",
            text: "Els vostres plats preferits, classificats (lleugers, per a sopar, per al táper, Thermomix…) i el menú de la setmana en dos tocs.",
            color: Paleta.verd
        )
        .navigationTitle("Menú")
    }
}
