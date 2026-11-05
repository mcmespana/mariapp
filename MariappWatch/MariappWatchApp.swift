import SwiftUI
import WidgetKit

@main
struct MariappWatchApp: App {
    @State private var magatzem = MagatzemRellotge.shared
    @Environment(\.scenePhase) private var fase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(magatzem)
                .tint(Paleta.aigua)
                .fontDesign(.rounded)
                .onAppear { magatzem.activa() }
        }
        .onChange(of: fase) { _, nova in
            if nova == .active { magatzem.refresca() }
        }
    }
}
