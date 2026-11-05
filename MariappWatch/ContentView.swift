import SwiftUI

/// Pestanyes verticals (gira la Digital Crown): aigua, cansòmetre, ràpids i Hui.
struct ContentView: View {
    enum Pestanya: String { case aigua, cansament, rapids, hui }

    @State private var pestanya: Pestanya = .aigua

    var body: some View {
        TabView(selection: $pestanya) {
            AiguaPantalla().tag(Pestanya.aigua)
            CansamentPantalla().tag(Pestanya.cansament)
            RapidsPantalla().tag(Pestanya.rapids)
            HuiPantalla().tag(Pestanya.hui)
        }
        .tabViewStyle(.verticalPage)
        .containerBackground(Paleta.fons.gradient, for: .tabView)
        // Les complicacions obrin la pantalla que toca (mariapp://aigua, …).
        .onOpenURL { url in
            if let host = url.host, let p = Pestanya(rawValue: host) { pestanya = p }
        }
    }
}

#Preview {
    ContentView().environment(MagatzemRellotge.shared)
}
