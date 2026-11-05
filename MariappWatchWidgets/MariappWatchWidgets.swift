import SwiftUI
import WidgetKit

@main
struct MariappWatchWidgets: WidgetBundle {
    var body: some Widget {
        AiguaComplicacio()
        CansamentComplicacio()
        CitaComplicacio()
    }
}

// MARK: - Proveïdor comú: llig l'estat que guarda l'app del rellotge

struct EntradaRellotge: TimelineEntry {
    let date: Date
    let estat: EstatRellotge
    var relevance: TimelineEntryRelevance? {
        // Smart Stack: la cita d'hui puja de posició.
        if let cita = estat.cita, Calendar.current.isDateInToday(cita.data), cita.data > date {
            return TimelineEntryRelevance(score: 100)
        }
        return nil
    }
}

struct ProveidorRellotge: TimelineProvider {
    func placeholder(in context: Context) -> EntradaRellotge {
        EntradaRellotge(date: Date(), estat: EstatRellotge(hui: HuiSnapshot(dia: ClauDia.avui, aiguaMl: 1500, cafes: 2, cansament: 400, escalaCansament: 1000)))
    }

    func getSnapshot(in context: Context, completion: @escaping (EntradaRellotge) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : EntradaRellotge(date: Date(), estat: EstatRellotge.carrega()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EntradaRellotge>) -> Void) {
        let ara = Date()
        let estat = EstatRellotge.carrega()
        var entrades = [EntradaRellotge(date: ara, estat: estat)]
        // Quan arriba l'hora de la cita, la complicació es buida sola.
        if let cita = estat.cita, cita.data > ara {
            var despres = estat
            despres.cita = nil
            entrades.append(EntradaRellotge(date: cita.data, estat: despres))
        }
        completion(Timeline(entries: entrades, policy: .after(ara.addingTimeInterval(1800))))
    }
}

private func litres(_ ml: Int) -> String { FormatAigua.text(ml) }

// MARK: - Aigua

struct AiguaComplicacio: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "es.mariapp.watch.aigua", provider: ProveidorRellotge()) { entrada in
            VistaAiguaComplicacio(hui: entrada.estat.hui)
                .containerBackground(for: .widget) { Color.clear }
                .widgetURL(URL(string: "mariapp://aigua"))
        }
        .configurationDisplayName("Aigua")
        .description("L'aigua d'hui i els cafés.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryRectangular, .accessoryInline])
    }
}

struct VistaAiguaComplicacio: View {
    @Environment(\.widgetFamily) private var familia
    let hui: HuiSnapshot

    var body: some View {
        switch familia {
        case .accessoryCorner:
            Image(systemName: "drop.fill")
                .font(.title3)
                .widgetLabel {
                    ProgressView(value: hui.progresAigua) { Text(litres(hui.aiguaMl)) }
                        .tint(Paleta.aigua)
                }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("💧 \(litres(hui.aiguaMl)) · ☕️ \(hui.cafes)")
                    .font(.system(.headline, design: .rounded))
                    .widgetAccentable()
                ProgressView(value: hui.progresAigua)
                    .tint(Paleta.aigua)
                Text("de \(litres(hui.objectiuMl))")
                    .font(.system(.caption2, design: .rounded))
            }
        case .accessoryInline:
            Text("💧 \(litres(hui.aiguaMl)) · ☕️ \(hui.cafes)")
        default:
            Gauge(value: hui.progresAigua) {
                Image(systemName: "drop.fill")
            } currentValueLabel: {
                Text(String(format: "%.1f", Double(hui.aiguaMl) / 1000).replacingOccurrences(of: ".", with: ","))
                    .font(.system(.body, design: .rounded).weight(.bold))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(Paleta.aigua)
        }
    }
}

// MARK: - Cansament

struct CansamentComplicacio: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "es.mariapp.watch.cansament", provider: ProveidorRellotge()) { entrada in
            VistaCansamentComplicacio(hui: entrada.estat.hui, escala: entrada.estat.escalaCansament)
                .containerBackground(for: .widget) { Color.clear }
                .widgetURL(URL(string: "mariapp://cansament"))
        }
        .configurationDisplayName("Cansament")
        .description("Com estàs de cansada hui.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner])
    }
}

struct VistaCansamentComplicacio: View {
    @Environment(\.widgetFamily) private var familia
    let hui: HuiSnapshot
    let escala: Int

    private var emoji: String {
        guard let c = hui.cansament else { return "🫖" }
        return EscalaRellotge.emoji(c, escala: escala)
    }

    var body: some View {
        switch familia {
        case .accessoryCorner:
            Text(emoji)
                .font(.title2)
                .widgetLabel(hui.cansament.map { "\($0) / \(escala)" } ?? "Apunta-ho")
        default:
            Gauge(value: Double(hui.cansament ?? 0), in: 0...Double(max(escala, 1))) {
                Text("😮‍💨")
            } currentValueLabel: {
                Text(emoji).font(.title3)
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(Gradient(colors: [Paleta.verd, Paleta.groc, Paleta.taronja]))
        }
    }
}

// MARK: - Pròxima cita

struct CitaComplicacio: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "es.mariapp.watch.cita", provider: ProveidorRellotge()) { entrada in
            VistaCitaComplicacio(cita: entrada.estat.cita)
                .containerBackground(for: .widget) { Color.clear }
                .widgetURL(URL(string: "mariapp://hui"))
        }
        .configurationDisplayName("Pròxima cita")
        .description("El metge que ve, amb compte enrere.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
    }
}

struct VistaCitaComplicacio: View {
    @Environment(\.widgetFamily) private var familia
    let cita: CitaSnapshot?

    var body: some View {
        if let cita {
            let avui = Calendar.current.isDateInToday(cita.data)
            switch familia {
            case .accessoryInline:
                Text("\(cita.emoji) \(cita.titol) ") + Text(cita.data, style: .relative)
            default:
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(cita.emoji) \(cita.titol)")
                        .font(.system(.headline, design: .rounded))
                        .lineLimit(1)
                        .widgetAccentable()
                    Text(avui ? "ÉS HUI! \(cita.data.formatted(date: .omitted, time: .shortened))" : cita.data.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                        .font(.caption)
                    Text(cita.data, style: .relative)
                        .font(.caption2)
                }
            }
        } else {
            switch familia {
            case .accessoryInline: Text("🎉 Cap cita pròxima")
            default: Text("🎉 Cap cita pròxima").font(.system(.footnote, design: .rounded))
            }
        }
    }
}
