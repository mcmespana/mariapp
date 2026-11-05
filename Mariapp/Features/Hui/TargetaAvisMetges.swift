import SwiftUI

/// A dalt de tot a Hui: si hi ha una cita en els pròxims 7 dies o una cita per demanar amb el recordatori vençut.
struct TargetaAvisMetges: View {
    @Environment(DataStore.self) private var store
    @Environment(Navegacio.self) private var nav

    var body: some View {
        let cites = store.cites.items
        let proxima = ServeiCites.citaProxima7Dies(cites)
        let vencudes = ServeiCites.perDemanarVencudes(cites)
        if proxima != nil || !vencudes.isEmpty {
            Button {
                nav.seccio = .metges
            } label: {
                Targeta(tint: Paleta.alerta) {
                    CapcaleraTargeta(icona: "cross.case.fill", titol: "🚨 Metges", color: Paleta.alerta) {
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                    if let proxima, let data = proxima.data {
                        let emoji = ServeiCites.categoria(proxima)?.emoji ?? "🏥"
                        Text("\(emoji) \(proxima.titol): \(Compte.text(fins: data))")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Paleta.alerta)
                        Text("\(Dates.llarga(data).capitalizedFirst) · \(Dates.hora(data))")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Paleta.tinta)
                    }
                    ForEach(vencudes) { c in
                        Label("Cal demanar cita: \(c.titol) 📞", systemImage: "phone.fill")
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundStyle(Paleta.tinta)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}
