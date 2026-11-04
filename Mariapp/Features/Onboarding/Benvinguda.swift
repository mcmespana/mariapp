import SwiftUI

/// Primera pantalla: qui fa servir aquest dispositiu?
struct Benvinguda: View {
    @Environment(Preferencies.self) private var prefs
    @State private var apareix = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                BolaClay(color: Paleta.groc, mida: 180)
                    .scaleEffect(apareix ? 1 : 0.6)
                BolaClay(color: Paleta.aigua, mida: 84)
                    .offset(x: 82, y: 64)
                    .scaleEffect(apareix ? 1 : 0.4)
                BolaClay(color: Paleta.verd, mida: 46)
                    .offset(x: -88, y: 58)
                    .scaleEffect(apareix ? 1 : 0.3)
                Text("🌻").font(.system(size: 84))
                    .rotationEffect(.degrees(apareix ? 0 : -30))
            }
            .animation(.spring(response: 0.9, dampingFraction: 0.6), value: apareix)

            VStack(spacing: 10) {
                Text("Benvinguda a Mariapp")
                    .font(.titolGran(32))
                    .foregroundStyle(Paleta.tinta)
                Text("Un raconet tranquil per a apuntar com va el dia, què sopem i quan toca metge.")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Paleta.tintaSuau)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }
            .opacity(apareix ? 1 : 0)
            .animation(.easeOut(duration: 0.8).delay(0.2), value: apareix)

            Spacer()

            VStack(spacing: 12) {
                Text("Qui eres?")
                    .font(.titolSeccio)
                    .foregroundStyle(Paleta.tinta)
                Button {
                    prefs.rol = .maria
                    Task { _ = await Avisos.demanaPermis(); Avisos.reprograma() }
                } label: {
                    Text("🌻  Soc la Maria").frame(maxWidth: .infinity)
                }
                .buttonStyle(.suau(Paleta.aigua, ple: true))

                Button {
                    prefs.rol = .david
                    Navegacio.shared.seccio = .ajustos
                } label: {
                    Text("🐻  Soc David (convidat)").frame(maxWidth: .infinity)
                }
                .buttonStyle(.suau(Paleta.taronja))
            }
            .frame(maxWidth: 360)
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { FonsAmbTaques() }
        .onAppear { apareix = true }
    }
}
