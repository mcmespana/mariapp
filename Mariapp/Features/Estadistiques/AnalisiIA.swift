import SwiftUI

/// "✨ Analitza el meu mes": envia resums AGREGATS (mai notes personals) i mostra unes observacions amables.
struct AnalisiIAView: View {
    let resum: String

    @State private var text: String?
    @State private var error: String?
    @State private var carregant = false

    var body: some View {
        Targeta(tint: Paleta.groc) {
            CapcaleraTargeta(icona: "sparkles", titol: "Mirada amable", color: Paleta.groc)
            BotoIA(titol: "✨ Analitza el meu mes", carregant: carregant, accio: analitza)
            ResultatIA(text: text, error: error, carregant: carregant)
        }
    }

    private func analitza() {
        carregant = true
        text = nil
        error = nil
        let sistema = ServeiIA.sistemaBase + """

        Ara fas d'amiga atenta: mira els números i diu 3 a 5 observacions cariñoses i pràctiques (llista amb guions, una frase cadascuna).
        Mai consells mèdics ni res alarmista; si alguna cosa pareix preocupant, suggerix amb dolçor comentar-ho amb la metgessa.
        """
        Task {
            do {
                text = try await ServeiIA.pregunta("Estes són les meues dades dels últims mesos (agregades):\n\(resum)", sistema: sistema, maxTokens: 800)
            } catch {
                self.error = error.missatgeIA
            }
            carregant = false
        }
    }
}
