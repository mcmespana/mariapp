import SwiftUI

struct Arrel: View {
    @Environment(Preferencies.self) private var prefs
    @Environment(Navegacio.self) private var nav

    var body: some View {
        Group {
            if prefs.rol == nil {
                Benvinguda()
            } else {
                Navegador()
            }
        }
        .animation(.smooth, value: prefs.rol)
    }
}

/// iPhone: pestanyes. Mac i iPad: barra lateral.
struct Navegador: View {
    @Environment(Navegacio.self) private var nav

    var body: some View {
        @Bindable var nav = nav
        #if os(macOS)
        NavigationSplitView {
            List(selection: Binding(get: { nav.seccio }, set: { if let s = $0 { nav.seccio = s } })) {
                Section {
                    ForEach(Seccio.principals) { fila($0) }
                }
                Section("Més") {
                    ForEach(Seccio.secundaries) { fila($0) }
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
            .scrollContentBackground(.hidden)
            .background(Paleta.paperFosc.opacity(0.5))
        } detail: {
            NavigationStack { vista(nav.seccio) }
        }
        #else
        TabView(selection: Binding(
            get: { Seccio.principals.contains(nav.seccio) ? nav.seccio : Seccio.estadistiques },
            set: { nav.seccio = $0 }
        )) {
            ForEach(Seccio.principals) { s in
                Tab(s.nom, systemImage: s.icona, value: s) {
                    NavigationStack { vista(s) }
                }
            }
            Tab("Més", systemImage: "ellipsis.circle.fill", value: Seccio.estadistiques) {
                Mes()
            }
        }
        #endif
    }

    private func fila(_ s: Seccio) -> some View {
        Label {
            Text(s.nom)
        } icon: {
            Image(systemName: s.icona).foregroundStyle(s.color)
        }
        .tag(s)
    }

    @ViewBuilder
    private func vista(_ s: Seccio) -> some View {
        Seccio.vista(s)
    }
}

extension Seccio {
    @ViewBuilder
    static func vista(_ s: Seccio) -> some View {
        switch s {
        case .hui: HuiView()
        case .calendari: CalendariView()
        case .menu: MenuView()
        case .metges: MetgesView()
        case .estadistiques: EstadistiquesView()
        case .david: DavidView()
        case .fills: FillsView()
        case .ajustos: AjustosView()
        }
    }
}

/// Pantalla "Més" de l'iPhone.
struct Mes: View {
    @Environment(Navegacio.self) private var nav
    @State private var cami: [Seccio] = []

    var body: some View {
        NavigationStack(path: $cami) {
            llista
                .navigationDestination(for: Seccio.self) { Seccio.vista($0) }
        }
        .onAppear { obriSiCal() }
        .onChange(of: nav.seccio) { _, _ in obriSiCal() }
    }

    /// Si un enllaç ens porta a una secció d'ací (p. ex. Ajustos), l'obrim.
    private func obriSiCal() {
        let s = nav.seccio
        if Seccio.secundaries.contains(s), s != .estadistiques, cami.last != s {
            cami = [s]
        }
    }

    private var llista: some View {
        List {
            ForEach(Seccio.secundaries) { s in
                NavigationLink(value: s) {
                    Label {
                        Text(s.nom).font(.system(.body, design: .rounded))
                    } icon: {
                        Image(systemName: s.icona).foregroundStyle(s.color)
                    }
                }
                .listRowBackground(Paleta.paper)
            }
        }
        .navigationTitle("Més")
        .fonsMariapp()
    }
}
