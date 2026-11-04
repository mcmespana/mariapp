import SwiftUI

/// Primera pantalla: qui fa servir aquest dispositiu?
struct Benvinguda: View {
    @Environment(Preferencies.self) private var prefs
    @State private var apareix = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle().fill(Paleta.groc.opacity(0.25)).frame(width: 190, height: 190)
                    .scaleEffect(apareix ? 1 : 0.6)
                Circle().fill(Paleta.aigua.opacity(0.25)).frame(width: 120, height: 120)
                    .offset(x: 60, y: 40)
                    .scaleEffect(apareix ? 1 : 0.4)
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
        .background(Paleta.fons.ignoresSafeArea())
        .onAppear { apareix = true }
    }
}
