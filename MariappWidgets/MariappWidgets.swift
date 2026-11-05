import SwiftUI
import WidgetKit

@main
struct MariappWidgets: WidgetBundle {
    var body: some Widget {
        HuiWidget()
        HuiLiveActivity()
        AiguaControl()
        CafeControl()
    }
}

// MARK: - Widget "Hui"

struct EntradaHui: TimelineEntry {
    let date: Date
    let snap: HuiSnapshot
}

struct ProveidorHui: TimelineProvider {
    func placeholder(in context: Context) -> EntradaHui {
        EntradaHui(date: Date(), snap: HuiSnapshot(dia: ClauDia.avui, aiguaMl: 1125, cafes: 2, queixes: 1))
    }

    func getSnapshot(in context: Context, completion: @escaping (EntradaHui) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : EntradaHui(date: Date(), snap: HuiSnapshot.carrega()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EntradaHui>) -> Void) {
        let ara = EntradaHui(date: Date(), snap: HuiSnapshot.carrega())
        // A mitjanit es reinicia el dia.
        let dema = Calendar.current.startOfDay(for: Date().addingTimeInterval(86_400))
        completion(Timeline(entries: [ara], policy: .after(dema)))
    }
}

struct HuiWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "es.mariapp.hui", provider: ProveidorHui()) { entrada in
            VistaWidgetHui(snap: entrada.snap)
                .containerBackground(for: .widget) { Paleta.fons }
        }
        .configurationDisplayName("Hui")
        .description("Aigua, cafés i queixes d'un toc.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

struct VistaWidgetHui: View {
    @Environment(\.widgetFamily) private var familia
    let snap: HuiSnapshot

    var body: some View {
        switch familia {
        case .accessoryCircular:
            Gauge(value: snap.progresAigua) {
                Image(systemName: "drop.fill")
            } currentValueLabel: {
                Text("\(Int(snap.progresAigua * 100))")
            }
            .gaugeStyle(.accessoryCircular)
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Label(FormatAigua.text(snap.aiguaMl), systemImage: "drop.fill")
                    .font(.headline)
                Text("☕️ \(snap.cafes)   😤 \(snap.queixes)")
                ProgressView(value: snap.progresAigua)
            }
        case .systemMedium:
            HStack(spacing: 14) {
                AnellAigua(snap: snap).frame(width: 96, height: 96)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hui")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(Paleta.tinta)
                    HStack(spacing: 6) {
                        Button(intent: SumaAiguaIntent(ml: snap.ampollaMl / 2)) { Text("💧 +½") }
                        Button(intent: SumaAiguaIntent(ml: snap.ampollaMl)) { Text("💧 +1") }
                    }
                    .tint(Paleta.aigua)
                    HStack(spacing: 6) {
                        Button(intent: SumaCafeIntent()) { Text("☕️ \(snap.cafes)") }
                            .tint(Paleta.cafe)
                        Button(intent: SumaQueixaIntent()) { Text("😤 \(snap.queixes)") }
                            .tint(Paleta.taronja)
                    }
                }
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .buttonStyle(.bordered)
            }
        default:
            VStack(spacing: 8) {
                AnellAigua(snap: snap).frame(width: 82, height: 82)
                Button(intent: SumaAiguaIntent(ml: snap.ampollaMl / 2)) {
                    Text("💧 +½ botella")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(Paleta.aigua)
            }
        }
    }
}

struct AnellAigua: View {
    let snap: HuiSnapshot

    var body: some View {
        ZStack {
            Circle().stroke(Paleta.aigua.opacity(0.18), lineWidth: 10)
            Circle()
                .trim(from: 0, to: snap.progresAigua)
                .stroke(Paleta.aigua, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text(FormatAigua.text(snap.aiguaMl))
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Paleta.tinta)
                    .minimumScaleFactor(0.6)
                Text("de \(FormatAigua.text(snap.objectiuMl))")
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(Paleta.tintaSuau)
            }
            .padding(10)
        }
    }
}

// MARK: - Controls (Centre de control / pantalla de bloqueig / botó d'Acció)

struct AiguaControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "es.mariapp.control.aigua") {
            ControlWidgetButton(action: SumaAiguaIntent(ml: HuiSnapshot.carrega().ampollaMl / 2)) {
                Label("Mitja botella", systemImage: "drop.fill")
            }
        }
        .displayName("Apuntar aigua")
        .description("Suma mitja botella d'aigua.")
    }
}

struct CafeControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "es.mariapp.control.cafe") {
            ControlWidgetButton(action: SumaCafeIntent()) {
                Label("Café", systemImage: "cup.and.saucer.fill")
            }
        }
        .displayName("Apuntar café")
    }
}
