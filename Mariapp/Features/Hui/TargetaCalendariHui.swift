import SwiftUI

/// "Hui al calendari": els esdeveniments d'hui (màxim 3), si hi ha permís.
struct TargetaCalendariHui: View {
    @Environment(ServeiCalendari.self) private var calendari
    @Environment(DataStore.self) private var store
    @Environment(Navegacio.self) private var nav

    var body: some View {
        if calendari.autoritzat {
            let cal = Calendar.current
            let ara = Date()
            let finsAra = calendari.esdeveniments.filter { e in
                (cal.isDateInToday(e.startDate) || (e.startDate < ara && e.endDate > ara)) && (e.isAllDay || e.endDate > ara)
            }
            Button {
                nav.seccio = .calendari
            } label: {
                Targeta(tint: Paleta.blau) {
                    CapcaleraTargeta(icona: "calendar", titol: "Hui al calendari", color: Paleta.blau) {
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                    if finsAra.isEmpty {
                        Text("Res més al calendari per a hui 🌿")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                    ForEach(Array(finsAra.prefix(3)), id: \.eventIdentifier) { e in
                        let a = store.anotacions[ServeiCalendari.clau(per: e)]
                        HStack(spacing: 8) {
                            Text(e.isAllDay ? "Tot el dia" : Dates.hora(e.startDate))
                                .font(.system(.caption, design: .rounded).bold())
                                .foregroundStyle(Paleta.tintaSuau)
                                .frame(width: 62, alignment: .leading)
                            Text("\(a?.emoji.map { $0 + " " } ?? "")\(e.title ?? "Sense títol")")
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                .foregroundStyle(Paleta.tinta)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            if let p = a?.propietari { Text(p.emoji) }
                        }
                    }
                    if finsAra.count > 3 {
                        Text("+ \(finsAra.count - 3) més")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}
