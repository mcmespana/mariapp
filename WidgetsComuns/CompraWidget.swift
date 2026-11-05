import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Widget "Llista de la compra" (verd, amb elements que es ratllen amb un toc)

struct EntradaCompra: TimelineEntry {
    let date: Date
    let compra: CompraSnapshot
}

struct ProveidorCompra: TimelineProvider {
    func placeholder(in context: Context) -> EntradaCompra {
        EntradaCompra(date: Date(), compra: CompraSnapshot(
            pendents: [
                ItemCompra(id: "1", nom: "Llet"), ItemCompra(id: "2", nom: "Pa"),
                ItemCompra(id: "3", nom: "Ous", quantitat: "12"), ItemCompra(id: "4", nom: "Tomaques"),
            ],
            totalPendents: 4
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (EntradaCompra) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : EntradaCompra(date: Date(), compra: CompraSnapshot.carrega()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EntradaCompra>) -> Void) {
        // L'app (o el mateix intent) recarrega el widget quan canvia la llista.
        let entrada = EntradaCompra(date: Date(), compra: CompraSnapshot.carrega())
        completion(Timeline(entries: [entrada], policy: .after(Date().addingTimeInterval(3600))))
    }
}

struct CompraWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "es.mariapp.compra", provider: ProveidorCompra()) { entrada in
            VistaWidgetCompra(compra: entrada.compra)
                .containerBackground(for: .widget) { Paleta.fons }
        }
        .configurationDisplayName("Llista de la compra")
        .description("El que falta per comprar. Toca un element per a ratllar-lo, sense obrir l'app.")
        .supportedFamilies(FamiliesWidget.compra)
    }
}

struct VistaWidgetCompra: View {
    @Environment(\.widgetFamily) private var familia
    let compra: CompraSnapshot

    var body: some View {
        Group {
            if compra.pendents.isEmpty {
                buit
            } else {
                contingut
            }
        }
        .environment(\.locale, FormatWidget.locale)
        .widgetURL(URL(string: "mariapp://compra"))
    }

    // MARK: Famílies

    @ViewBuilder
    private var contingut: some View {
        switch familia {
        #if os(iOS)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text("🛒 \(compra.totalPendents) per comprar").font(.headline)
                Text(compra.pendents.prefix(4).map(\.nom).joined(separator: ", ") + (compra.totalPendents > 4 ? "…" : ""))
                    .font(.caption)
                    .lineLimit(2)
            }
        #endif
        case .systemMedium:
            VStack(alignment: .leading, spacing: 6) {
                capcalera
                files(maxim: 4)
                Spacer(minLength: 0)
            }
        case .systemLarge:
            VStack(alignment: .leading, spacing: 8) {
                capcalera
                files(maxim: 10)
                Spacer(minLength: 0)
            }
        default:
            // Petit: un resum sense botons (cap fila cabria bé amb el dit).
            VStack(alignment: .leading, spacing: 6) {
                Text("🛒").font(.system(size: 26))
                Text("\(compra.totalPendents) per comprar")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Paleta.verd)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                ForEach(compra.pendents.prefix(3)) { item in
                    Text("· \(item.nom)")
                        .font(.system(.footnote, design: .rounded).weight(.medium))
                        .foregroundStyle(Paleta.tinta)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var capcalera: some View {
        HStack {
            Text("🛒 Per comprar")
                .font(.system(.headline, design: .serif))
                .foregroundStyle(Paleta.verd)
            Spacer()
            Text("\(compra.totalPendents)")
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(Paleta.verd)
        }
    }

    @ViewBuilder
    private func files(maxim: Int) -> some View {
        let visibles = Array(compra.pendents.prefix(maxim))
        let mes = max(0, compra.totalPendents - visibles.count)
        VStack(alignment: .leading, spacing: 2) {
            ForEach(visibles) { item in
                Button(intent: MarcaCompratIntent(id: item.id)) {
                    HStack(spacing: 10) {
                        Image(systemName: "circle")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Paleta.verd)
                        Text(item.nom)
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundStyle(Paleta.tinta)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        if let q = item.quantitat, !q.isEmpty {
                            Text(q)
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundStyle(Paleta.tintaSuau)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 26, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .invalidatableContent()
            }
            if mes > 0 {
                Text("+ \(mes) més")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(Paleta.tintaSuau)
                    .padding(.top, 2)
            }
        }
    }

    private var buit: some View {
        VStack(spacing: 6) {
            Text("🎉").font(.system(size: 34))
            Text("Res a comprar")
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundStyle(Paleta.verd)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
