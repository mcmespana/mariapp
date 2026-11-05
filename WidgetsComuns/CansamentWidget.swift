import SwiftUI
import WidgetKit

// MARK: - Widget de cansament: obri l'app al cansòmetre (mariapp://cansament)

struct ProveidorCansament: TimelineProvider {
    func placeholder(in context: Context) -> EntradaHui {
        var s = HuiSnapshot(dia: ClauDia.avui)
        s.cansament = 400
        return EntradaHui(date: Date(), snap: s)
    }

    func getSnapshot(in context: Context, completion: @escaping (EntradaHui) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : EntradaHui(date: Date(), snap: HuiSnapshot.carrega()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EntradaHui>) -> Void) {
        let dema = Calendar.current.startOfDay(for: Date().addingTimeInterval(86_400))
        completion(Timeline(entries: [EntradaHui(date: Date(), snap: HuiSnapshot.carrega())], policy: .after(dema)))
    }
}

struct CansamentWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "es.mariapp.cansament", provider: ProveidorCansament()) { entrada in
            VistaWidgetCansament(snap: entrada.snap)
                .containerBackground(for: .widget) { Paleta.fons }
        }
        .configurationDisplayName("Cansòmetre")
        .description("Un toc i s'obri el cansòmetre per a apuntar com estàs.")
        .supportedFamilies(FamiliesWidget.cansament)
    }
}

struct VistaWidgetCansament: View {
    @Environment(\.widgetFamily) private var familia
    let snap: HuiSnapshot

    private var emoji: String {
        guard let c = snap.cansament else { return "🫖" }
        let r = Double(c) / Double(max(snap.escalaCansament ?? 1000, 1))
        switch r {
        case ..<0.2: return "🤩"
        case ..<0.4: return "😊"
        case ..<0.6: return "😐"
        case ..<0.8: return "😮‍💨"
        default: return "🧟‍♀️"
        }
    }

    var body: some View {
        Group {
            switch familia {
            #if os(iOS)
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 0) {
                        Text(emoji).font(.title3)
                        Text(snap.cansament.map(String.init) ?? "?").font(.caption2.bold())
                    }
                }
            #endif
            default:
                VStack(spacing: 6) {
                    Text(emoji)
                        .font(.system(size: 44))
                    Text(snap.cansament == nil ? "Com estàs de cansada?" : "Cansament: \(snap.cansament ?? 0)")
                        .font(.system(.footnote, design: .rounded).weight(.bold))
                        .foregroundStyle(Paleta.tinta)
                        .multilineTextAlignment(.center)
                    Text(snap.cansament == nil ? "Toca per a apuntar-ho" : "Toca per a canviar-ho")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(Paleta.tintaSuau)
                }
            }
        }
        .widgetURL(URL(string: "mariapp://cansament"))
    }
}
