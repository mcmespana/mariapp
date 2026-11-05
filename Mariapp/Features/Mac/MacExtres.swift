#if os(macOS)
import AppKit
import SwiftUI

/// Icona 💧 a la barra de menús: aigua d'hui i botons ràpids.
struct MenuBarMariapp: View {
    @Environment(DataStore.self) private var store
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let dia = store.avui
        let cfg = store.config
        let progres = cfg.objectiuMl > 0 ? min(Double(dia.aiguaMl) / Double(cfg.objectiuMl), 1) : 0

        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text("💧")
                    .font(.system(size: 28))
                    .background { BolaClay(color: Paleta.aigua, mida: 54) }
                    .padding(.trailing, 4)
                VStack(alignment: .leading, spacing: 2) {
                    Text(FormatAigua.text(dia.aiguaMl))
                        .font(.titolGran(26))
                        .foregroundStyle(Paleta.tinta)
                        .contentTransition(.numericText())
                    Text("de \(FormatAigua.text(cfg.objectiuMl)) · ☕️ \(dia.cafes) · 😤 \(dia.queixes)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Paleta.tintaSuau)
                }
            }
            ProgressView(value: progres)
                .tint(Paleta.aigua)

            HStack(spacing: 8) {
                Button("+ ½") { aigua(cfg.ampollaMl / 2) }
                Button("+ 1") { aigua(cfg.ampollaMl) }
            }
            HStack(spacing: 8) {
                Button("☕️ Café") {
                    store.suma(.cafes, 1)
                    Sons.toca(.cafe)
                }
                Button("😤 Queixa") {
                    store.suma(.queixes, 1)
                    Sons.toca(.queixa)
                }
            }
            Divider()
            Button("Obrir Mariapp") {
                NSApp.activate(ignoringOtherApps: true)
                if let finestra = NSApp.windows.first(where: { $0.canBecomeMain }) {
                    finestra.makeKeyAndOrderFront(nil)
                } else {
                    openWindow(id: "principal")
                }
            }
        }
        .buttonStyle(.suau(Paleta.aigua))
        .padding(16)
        .frame(width: 280)
        .animation(Clay.molla, value: dia.aiguaMl)
    }

    private func aigua(_ ml: Int) {
        store.suma(.aiguaMl, ml)
        Sons.toca(.gota)
    }
}

/// Menú "Mariapp": ⌘1…⌘9 per a les seccions, ⌘⇧A aigua, ⌘⇧C café.
struct ComandesMariapp: Commands {
    var body: some Commands {
        CommandMenu("Mariapp") {
            ForEach(Array(Seccio.allCases.prefix(9).enumerated()), id: \.element) { i, s in
                Button(s.nom) { Navegacio.shared.seccio = s }
                    .keyboardShortcut(KeyEquivalent(Character(String(i + 1))), modifiers: .command)
            }
            Divider()
            Button("Apuntar mitja botella 💧") {
                let store = DataStore.shared
                store.suma(.aiguaMl, store.config.ampollaMl / 2)
                Sons.toca(.gota)
            }
            .keyboardShortcut("a", modifiers: [.command, .shift])
            Button("Apuntar un café ☕️") {
                DataStore.shared.suma(.cafes, 1)
                Sons.toca(.cafe)
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
        }
    }
}
#endif
