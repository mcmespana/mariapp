import SwiftUI

/// "Soft clay": plastilina suau damunt de crema.
/// Volum amb llum interior (dalt-esquerra), ombra interior (baix-dreta) i ombra exterior tenyida del color de la secció.
enum Clay {
    static let radiGran: CGFloat = 30
    static let radiMitja: CGFloat = 20
    static let radiXicotet: CGFloat = 14

    /// Molla per defecte (sense rebot) i molla juganera (quan hi ha "impuls", p. ex. en soltar un botó).
    static let molla = Animation.spring(response: 0.35, dampingFraction: 1.0)
    static let mollaJuganera = Animation.spring(response: 0.3, dampingFraction: 0.62)
}

/// Fons de plastilina per a qualsevol forma arredonida.
struct FonsClay: View {
    var tint: Color
    var radi: CGFloat = Clay.radiGran
    /// 0 = enfonsat (premut), 1 = normal, >1 = més inflat.
    var elevacio: CGFloat = 1
    /// Plastilina de color (botons plens) en lloc de crema.
    var ple: Bool = false

    @Environment(\.colorScheme) private var esquema

    var body: some View {
        let fosc = esquema == .dark
        let e = max(elevacio, 0.15)
        let forma = RoundedRectangle(cornerRadius: radi, style: .continuous)
        let colors: [Color] = ple
            ? [tint.mix(with: .white, by: fosc ? 0.12 : 0.28), tint]
            : [Paleta.clayLlum, Paleta.paper]

        forma
            .fill(
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .shadow(.inner(color: Color.white.opacity(ple ? 0.45 : (fosc ? 0.07 : 0.9)), radius: 3 * e, x: 2.5 * e, y: 2.5 * e))
                    .shadow(.inner(color: (ple ? Color.black : tint).opacity(ple ? 0.16 : (fosc ? 0.22 : 0.13)), radius: 6 * e, x: -3 * e, y: -4 * e))
            )
            .overlay {
                if !ple {
                    forma.fill(LinearGradient(colors: [tint.opacity(fosc ? 0.10 : 0.07), .clear], startPoint: .topLeading, endPoint: .center))
                }
            }
            // Ombra tenyida: la plastilina "pesa" i deixa color al terra.
            .shadow(color: tint.opacity(fosc ? 0.30 : (ple ? 0.38 : 0.20)), radius: 14 * e, x: 0, y: 9 * e)
            // Llum externa: fa que sobreïsca del fons crema.
            .shadow(color: Color.white.opacity(fosc ? 0.02 : 0.65), radius: 8 * e, x: -4 * e, y: -4 * e)
    }
}

extension View {
    /// Posa aquesta vista damunt d'un tros de plastilina.
    func clay(_ tint: Color = Paleta.tintaSuau, radi: CGFloat = Clay.radiGran, elevacio: CGFloat = 1, ple: Bool = false) -> some View {
        background { FonsClay(tint: tint, radi: radi, elevacio: elevacio, ple: ple) }
    }
}

/// Fons de l'app: crema amb taques de color molt difuminades (estàtiques, sense moviment).
struct FonsAmbTaques: View {
    var body: some View {
        ZStack {
            Paleta.fons
            Circle().fill(Paleta.groc.opacity(0.20)).frame(width: 340).blur(radius: 90).offset(x: 150, y: -260)
            Circle().fill(Paleta.aigua.opacity(0.16)).frame(width: 300).blur(radius: 100).offset(x: -170, y: 40)
            Circle().fill(Paleta.verd.opacity(0.12)).frame(width: 320).blur(radius: 110).offset(x: 140, y: 380)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Insígnia d'icona com un caramel de plastilina.
struct IconaClay: View {
    let icona: String
    let color: Color
    var mida: CGFloat = 34

    var body: some View {
        Image(systemName: icona)
            .font(.system(size: mida * 0.44, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: mida, height: mida)
            .clay(color, radi: mida * 0.36, elevacio: 0.45, ple: true)
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 24) {
        Text("Plastilina").padding(30).clay(Paleta.aigua)
        Text("Botó").foregroundStyle(.white).padding(16).clay(Paleta.taronja, radi: 20, ple: true)
        IconaClay(icona: "drop.fill", color: Paleta.aigua)
    }
    .padding(40)
    .background(FonsAmbTaques())
}

/// Bola de plastilina (la icona clàssica del claymorphism).
struct BolaClay: View {
    let color: Color
    var mida: CGFloat = 120

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.mix(with: .white, by: 0.55), color.mix(with: .white, by: 0.1), color],
                    center: UnitPoint(x: 0.35, y: 0.3),
                    startRadius: 2,
                    endRadius: mida * 0.75
                )
                .shadow(.inner(color: Color.black.opacity(0.12), radius: mida * 0.08, x: -mida * 0.04, y: -mida * 0.06))
            )
            .frame(width: mida, height: mida)
            .shadow(color: color.opacity(0.4), radius: mida * 0.16, x: 0, y: mida * 0.12)
            .accessibilityHidden(true)
    }
}
