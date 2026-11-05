#if os(iOS)
import SwiftUI

/// Ajustos › Apple Salut ❤️ (només a l'iPhone de la Maria).
struct SeccioSalut: View {
    @Environment(Preferencies.self) private var prefs
    @State private var salut = ServeiSalut.shared
    @State private var connectant = false
    @State private var sensePermis = false

    var body: some View {
        @Bindable var prefs = prefs
        Section {
            if !salut.disponible {
                Text("Apple Salut no està disponible en este dispositiu.")
                    .foregroundStyle(Paleta.tintaSuau)
            } else {
                Button {
                    connecta()
                } label: {
                    HStack {
                        Label(salut.connectat ? "Torna a revisar els permisos" : "Connectar amb Salut", systemImage: "heart.text.square.fill")
                        Spacer()
                        if connectant { ProgressView().controlSize(.small) }
                    }
                }
                .disabled(connectant)

                Toggle("🏋️ Gimnàs sol amb els entrenaments", isOn: $prefs.salutGimnas)
                    .disabled(!salut.connectat)
                Toggle("💧 L'aigua també a Salut", isOn: $prefs.salutAigua)
                    .disabled(!salut.connectat)
                Toggle("😴 Llegir el son", isOn: $prefs.salutSon)
                    .disabled(!salut.connectat)
            }
        } header: {
            Text("Apple Salut ❤️")
        } footer: {
            Text("Es llig: els entrenaments (per a marcar el gimnàs, p. ex. des de l'Apple Watch) i el son (per a creuar-lo amb el cansament). S'escriu: l'aigua que apuntes. Res més, i res surt del teu compte.")
        }
        .listRowBackground(Paleta.paper)
        .sensoryFeedback(.success, trigger: salut.connectat)
        .alert("No he pogut demanar el permís", isPresented: $sensePermis) {
            Button("Val", role: .cancel) {}
        } message: {
            Text("Pots donar-lo a Ajustos del sistema › Salut › Accés a les dades i dispositius › Mariapp.")
        }
    }

    private func connecta() {
        connectant = true
        Task {
            let be = await salut.demanaPermis()
            if be {
                // Primera volta: tot encés. Les voltes següents, la Maria ja ha triat.
                if !UserDefaults.standard.bool(forKey: "salut.preferenciesInicials") {
                    UserDefaults.standard.set(true, forKey: "salut.preferenciesInicials")
                    prefs.salutGimnas = true
                    prefs.salutAigua = true
                    prefs.salutSon = true
                }
                await salut.sincronitzaTot()
            } else {
                sensePermis = true
            }
            connectant = false
        }
    }
}
#endif
