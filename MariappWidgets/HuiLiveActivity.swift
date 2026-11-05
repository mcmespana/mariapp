import ActivityKit
import SwiftUI
import WidgetKit

/// Activitat en directe: pantalla de bloqueig i Dynamic Island, amb botons d'un toc.
struct HuiLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HuiActivityAttributes.self) { context in
            PantallaBloqueig(estat: context.state)
                .padding(16)
                .activityBackgroundTint(Paleta.fons)
                .activitySystemActionForegroundColor(Paleta.tinta)
        } dynamicIsland: { context in
            let e = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        BotellaMini(progres: e.progres)
                            .frame(width: 20, height: 44)
                        Text(FormatAigua.text(e.aiguaMl))
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Paleta.aigua)
                            .contentTransition(.numericText())
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("☕️ \(e.cafes)  😤 \(e.queixes)")
                        .font(.system(.subheadline, design: .rounded))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Button(intent: SumaAiguaIntent(ml: e.ampollaMl / 2)) { Text("💧 +½") }
                        Button(intent: SumaAiguaIntent(ml: e.ampollaMl)) { Text("💧 +1") }
                        Button(intent: SumaCafeIntent()) { Text("☕️ +1") }
                    }
                    .buttonStyle(.bordered)
                    .tint(Paleta.aigua)
                }
            } compactLeading: {
                Image(systemName: "drop.fill").foregroundStyle(Paleta.aigua)
            } compactTrailing: {
                Text("\(Int(e.progres * 100))%")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(Paleta.aigua)
            } minimal: {
                Gauge(value: e.progres) { Image(systemName: "drop.fill") }
                    .gaugeStyle(.accessoryCircularCapacity)
                    .tint(Paleta.aigua)
            }
        }
    }
}

private struct PantallaBloqueig: View {
    let estat: HuiActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().stroke(Paleta.aigua.opacity(0.2), lineWidth: 7)
                    Circle().trim(from: 0, to: estat.progres)
                        .stroke(Paleta.aigua, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "drop.fill").foregroundStyle(Paleta.aigua)
                }
                .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(FormatAigua.text(estat.aiguaMl)) de \(FormatAigua.text(estat.objectiuMl))")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Paleta.tinta)
                    Text("☕️ \(estat.cafes) cafés · 😤 \(estat.queixes) queixes")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Paleta.tintaSuau)
                }
                Spacer()
            }
            HStack(spacing: 8) {
                Button(intent: SumaAiguaIntent(ml: estat.ampollaMl / 2)) { Text("💧 +½").frame(maxWidth: .infinity) }
                    .tint(Paleta.aigua)
                Button(intent: SumaAiguaIntent(ml: estat.ampollaMl)) { Text("💧 +1").frame(maxWidth: .infinity) }
                    .tint(Paleta.aigua)
                Button(intent: SumaCafeIntent()) { Text("☕️ +1").frame(maxWidth: .infinity) }
                    .tint(Paleta.cafe)
                Button(intent: SumaQueixaIntent()) { Text("😤 +1").frame(maxWidth: .infinity) }
                    .tint(Paleta.taronja)
            }
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .buttonStyle(.bordered)
        }
    }
}

/// Botella xicoteta: l'aigua puja suaument cada vegada que s'apunta alguna cosa.
private struct BotellaMini: View {
    let progres: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Paleta.aigua.opacity(0.5), lineWidth: 2)
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Paleta.aigua.gradient)
                    .frame(height: max(4, (geo.size.height - 4) * progres))
                    .padding(2)
            }
        }
        .animation(.smooth(duration: 0.6), value: progres)
    }
}
