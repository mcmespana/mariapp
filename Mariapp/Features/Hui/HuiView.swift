import SwiftUI

struct HuiView: View {
    @Environment(DataStore.self) private var store
    @Environment(Preferencies.self) private var prefs
    @Environment(Navegacio.self) private var nav

    var body: some View {
        @Bindable var nav = nav
        let dia = store.avui
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Salutacio()
                if !prefs.esMaria {
                    Targeta(tint: Paleta.taronja) {
                        Label("Estàs veient el dia de la Maria. Mira però no toques 👀", systemImage: "eye")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Paleta.tinta)
                    }
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16, alignment: .top)], spacing: 16) {
                    TargetaAigua(dia: dia)
                    TargetaCansament(dia: dia)
                    TargetaGimnas(dia: dia)
                    TargetaCafes(dia: dia)
                    TargetaDolor(dia: dia)
                    TargetaQueixes(dia: dia)
                    TargetaNota(dia: dia)
                }
                .disabled(!prefs.esMaria)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .fonsMariapp()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    EstadistiquesView()
                } label: {
                    Image(systemName: "chart.bar.xaxis")
                }
                .accessibilityLabel("Estadístiques")
            }
        }
        .sheet(isPresented: $nav.mostraCansament) {
            TriaCansament(dia: dia)
                .presentationDetents([.medium])
        }
    }
}

private struct Salutacio: View {
    @Environment(Preferencies.self) private var prefs

    var body: some View {
        TimelineView(.everyMinute) { context in
            let hora = Calendar.current.component(.hour, from: context.date)
            VStack(alignment: .leading, spacing: 4) {
                Text(Dates.llarga(context.date).capitalizedFirst)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(Paleta.tintaSuau)
                Text(salutacio(hora))
                    .font(.titolGran(32))
                    .foregroundStyle(Paleta.tinta)
            }
            .padding(.top, 8)
        }
    }

    private func salutacio(_ hora: Int) -> String {
        let nom = prefs.esMaria ? "Maria" : "David"
        switch hora {
        case 6..<13: return "Bon dia, \(nom) ☀️"
        case 13..<21: return "Bona vesprada, \(nom) 🌤️"
        default: return "Bona nit, \(nom) 🌙"
        }
    }
}

extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
