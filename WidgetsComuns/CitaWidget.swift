import SwiftUI
import WidgetKit

// MARK: - Widget "Pròxima cita" (roig, amb compte enrere)

struct EntradaCita: TimelineEntry {
    let date: Date
    let cita: CitaSnapshot?
}

struct ProveidorCita: TimelineProvider {
    func placeholder(in context: Context) -> EntradaCita {
        EntradaCita(date: Date(), cita: CitaSnapshot(titol: "Revisió", emoji: "🩺", data: Date().addingTimeInterval(3 * 86_400), lloc: "CAP"))
    }

    func getSnapshot(in context: Context, completion: @escaping (EntradaCita) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : EntradaCita(date: Date(), cita: CitaSnapshot.carrega()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EntradaCita>) -> Void) {
        let ara = Date()
        let cita = CitaSnapshot.carrega(ara: ara)
        var entrades = [EntradaCita(date: ara, cita: cita)]
        // Quan arriba l'hora de la cita, el widget es buida sol.
        if let cita { entrades.append(EntradaCita(date: cita.data, cita: nil)) }
        completion(Timeline(entries: entrades, policy: .after(ara.addingTimeInterval(3600))))
    }
}

struct CitaWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "es.mariapp.cita", provider: ProveidorCita()) { entrada in
            VistaWidgetCita(cita: entrada.cita)
                .containerBackground(for: .widget) { Paleta.alertaFons }
        }
        .configurationDisplayName("Pròxima cita")
        .description("El metge que ve, amb compte enrere. Que no se t'oblide!")
        .supportedFamilies(FamiliesWidget.cita)
        .contentMarginsDisabled()
    }
}

struct VistaWidgetCita: View {
    @Environment(\.widgetFamily) private var familia
    let cita: CitaSnapshot?

    var body: some View {
        Group {
            if let cita {
                contingut(cita)
            } else {
                buit
            }
        }
        .environment(\.locale, FormatWidget.locale)
        .widgetURL(URL(string: "mariapp://metges"))
    }

    private var buit: some View {
        VStack(spacing: 6) {
            Text("🎉").font(.system(size: 34))
            Text("Cap cita pròxima")
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundStyle(Paleta.alerta)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func contingut(_ cita: CitaSnapshot) -> some View {
        let avui = Calendar.current.isDateInToday(cita.data)
        switch familia {
        #if os(iOS)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text("\(cita.emoji) \(cita.titol)").font(.headline).lineLimit(1)
                Text(avui ? "ÉS HUI! \(FormatWidget.hora(cita.data))" : FormatWidget.diaLlarg(cita.data))
                    .font(.caption)
                Text(cita.data, style: .relative).font(.caption2)
            }
        #endif
        case .systemMedium:
            HStack(spacing: 14) {
                Text(cita.emoji).font(.system(size: 52))
                VStack(alignment: .leading, spacing: 4) {
                    etiquetaProxima
                    Text(cita.titol)
                        .font(.system(.title3, design: .serif).weight(.semibold))
                        .foregroundStyle(Paleta.tinta)
                        .lineLimit(2)
                    compta(cita, avui: avui)
                    Text("\(FormatWidget.diaLlarg(cita.data)) · \(FormatWidget.hora(cita.data))\(cita.lloc.isEmpty ? "" : " · \(cita.lloc)")")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Paleta.tintaSuau)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
        default:
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(cita.emoji).font(.system(size: 30))
                    Spacer()
                }
                etiquetaProxima
                Text(cita.titol)
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Paleta.tinta)
                    .lineLimit(2)
                Spacer(minLength: 0)
                compta(cita, avui: avui)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var etiquetaProxima: some View {
        Text("PRÒXIMA CITA")
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .foregroundStyle(Paleta.alerta)
    }

    @ViewBuilder
    private func compta(_ cita: CitaSnapshot, avui: Bool) -> some View {
        if avui {
            Text("ÉS HUI!!! 🏃‍♀️")
                .font(.system(.subheadline, design: .rounded).weight(.black))
                .foregroundStyle(Paleta.alerta)
        } else {
            Text(cita.data, style: .relative)
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(Paleta.alerta)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
    }
}
