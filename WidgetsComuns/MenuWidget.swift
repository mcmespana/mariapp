import SwiftUI
import WidgetKit

// MARK: - Widget "Menú de hui"

struct EntradaWidgetMenu: TimelineEntry {
    let date: Date
    let menu: ParellaMenu?
}

struct ProveidorMenu: TimelineProvider {
    func placeholder(in context: Context) -> EntradaWidgetMenu {
        EntradaWidgetMenu(date: Date(), menu: ParellaMenu(dinar: "🥗 Amanida de cigrons", sopar: "🎃 Crema de carabassa"))
    }

    func getSnapshot(in context: Context, completion: @escaping (EntradaWidgetMenu) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : EntradaWidgetMenu(date: Date(), menu: MenuSnapshot.carrega().per(Date())))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EntradaWidgetMenu>) -> Void) {
        let snap = MenuSnapshot.carrega()
        let ara = Date()
        let dema = Calendar.current.startOfDay(for: ara.addingTimeInterval(86_400))
        let entrades = [
            EntradaWidgetMenu(date: ara, menu: snap.per(ara)),
            EntradaWidgetMenu(date: dema, menu: snap.per(dema)),
        ]
        completion(Timeline(entries: entrades, policy: .atEnd))
    }
}

struct MenuWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "es.mariapp.menu", provider: ProveidorMenu()) { entrada in
            VistaWidgetMenu(menu: entrada.menu)
                .containerBackground(for: .widget) { Paleta.fons }
        }
        .configurationDisplayName("Menú d'hui")
        .description("Què hi ha per a dinar i per a sopar.")
        .supportedFamilies(FamiliesWidget.menu)
    }
}

struct VistaWidgetMenu: View {
    @Environment(\.widgetFamily) private var familia
    let menu: ParellaMenu?

    var body: some View {
        Group {
            switch familia {
            #if os(iOS)
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 1) {
                    Text("Menú d'hui").font(.headline)
                    Text("☀️ \(menu?.dinar ?? "—")").lineLimit(1)
                    Text("🌙 \(menu?.sopar ?? "—")").lineLimit(1)
                }
                .font(.caption)
            #endif
            case .systemMedium:
                VStack(alignment: .leading, spacing: 10) {
                    titol
                    HStack(alignment: .top, spacing: 12) {
                        forat("☀️ Dinar", menu?.dinar)
                        forat("🌙 Sopar", menu?.sopar)
                    }
                }
            default:
                VStack(alignment: .leading, spacing: 8) {
                    titol
                    forat("☀️ Dinar", menu?.dinar)
                    forat("🌙 Sopar", menu?.sopar)
                }
            }
        }
        .environment(\.locale, FormatWidget.locale)
        .widgetURL(URL(string: "mariapp://menu"))
    }

    private var titol: some View {
        Text("Menú d'hui")
            .font(.system(.headline, design: .serif))
            .foregroundStyle(Paleta.verd)
    }

    private func forat(_ etiqueta: String, _ text: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(etiqueta)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(Paleta.tintaSuau)
            Text(text ?? "Sense posar")
                .font(.system(.footnote, design: .rounded).weight(.medium))
                .foregroundStyle(text == nil ? Paleta.tintaSuau : Paleta.tinta)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
