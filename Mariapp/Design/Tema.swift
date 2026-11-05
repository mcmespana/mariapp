import SwiftUI

// MARK: - Tipografia
// Títols amb serif (New York): calma, revista de cuina. Cos amb arrodonida (SF Rounded): amable.

extension Font {
    static func titolGran(_ mida: CGFloat = 34) -> Font { .system(size: mida, weight: .semibold, design: .serif) }
    static let titolSeccio = Font.system(.title3, design: .serif).weight(.semibold)
    static let titolTargeta = Font.system(.headline, design: .rounded)
    static let numeroGran = Font.system(size: 40, weight: .bold, design: .rounded)
}

// MARK: - Fons

struct FonsMariapp: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background { FonsAmbTaques() }
    }
}

extension View {
    func fonsMariapp() -> some View { modifier(FonsMariapp()) }
}

// MARK: - Targeta

/// La peça bàsica: un tros de plastilina crema, amb l'ombra tenyida del color de la secció.
struct Targeta<Contingut: View>: View {
    var tint: Color? = nil
    @ViewBuilder var contingut: Contingut

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            contingut
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clay(tint ?? Paleta.tintaSuau)
    }
}

/// Capçalera d'una targeta: icona-caramel + títol + (opcional) alguna cosa a la dreta.
struct CapcaleraTargeta<Dreta: View>: View {
    let icona: String
    let titol: String
    let color: Color
    @ViewBuilder var dreta: Dreta

    init(icona: String, titol: String, color: Color, @ViewBuilder dreta: () -> Dreta) {
        self.icona = icona
        self.titol = titol
        self.color = color
        self.dreta = dreta()
    }

    var body: some View {
        HStack(spacing: 12) {
            IconaClay(icona: icona, color: color)
            Text(titol)
                .font(.titolTargeta)
                .foregroundStyle(Paleta.tinta)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            dreta
        }
    }
}

extension CapcaleraTargeta where Dreta == EmptyView {
    init(icona: String, titol: String, color: Color) {
        self.init(icona: icona, titol: titol, color: color) { EmptyView() }
    }
}

// MARK: - Botons

/// Botó de plastilina: s'enfonsa en prémer-lo i torna amb un botet en soltar-lo.
struct BotoSuau: ButtonStyle {
    var color: Color = Paleta.aigua
    var ple: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let premut = configuration.isPressed
        configuration.label
            .font(.system(.subheadline, design: .rounded).bold())
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .frame(minHeight: 44)
            .foregroundStyle(ple ? Color.white : color)
            .background {
                FonsClay(tint: color, radi: 22, elevacio: premut ? 0.25 : 0.6, ple: ple)
            }
            .scaleEffect(premut ? 0.95 : 1)
            .offset(y: premut ? 1.5 : 0)
            .animation(premut ? Clay.molla : Clay.mollaJuganera, value: premut)
    }
}

extension ButtonStyle where Self == BotoSuau {
    static func suau(_ color: Color, ple: Bool = false) -> BotoSuau { BotoSuau(color: color, ple: ple) }
}

/// Botó rodó petit (+ / −). Sempre amb text per a VoiceOver.
struct BotoRodo: View {
    let titol: String
    let icona: String
    let color: Color
    let accio: () -> Void

    var body: some View {
        Button(titol, systemImage: icona, action: accio)
            .labelStyle(.iconOnly)
            .buttonStyle(BotoRodoEstil(color: color))
    }
}

private struct BotoRodoEstil: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        let premut = configuration.isPressed
        configuration.label
            .font(.system(size: 16, weight: .heavy))
            .foregroundStyle(color)
            .frame(width: 44, height: 44)
            .background { FonsClay(tint: color, radi: 22, elevacio: premut ? 0.2 : 0.55) }
            .scaleEffect(premut ? 0.9 : 1)
            .animation(premut ? Clay.molla : Clay.mollaJuganera, value: premut)
    }
}

// MARK: - Xips

struct Xip: View {
    let text: String
    var color: Color = Paleta.tintaSuau
    var seleccionat: Bool = false

    var body: some View {
        Text(text)
            .font(.system(.caption, design: .rounded).bold())
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .foregroundStyle(seleccionat ? .white : color)
            .background {
                if seleccionat {
                    FonsClay(tint: color, radi: 14, elevacio: 0.35, ple: true)
                } else {
                    Capsule().fill(color.opacity(0.12))
                }
            }
    }
}

// MARK: - Placeholder bonic per a seccions encara per fer

struct EnConstruccio: View {
    let emoji: String
    let titol: String
    let text: String
    var color: Color = Paleta.groc

    @State private var bota = false
    @Environment(\.accessibilityReduceMotion) private var reduirMoviment

    var body: some View {
        VStack(spacing: 18) {
            Text(emoji)
                .font(.system(size: 64))
                .background { BolaClay(color: color, mida: 130) }
                .padding(.bottom, 12)
                .scaleEffect(bota ? 1.06 : 0.96)
                .rotationEffect(.degrees(bota ? 3 : -3))
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: bota)
            Text(titol)
                .font(.titolGran(26))
                .foregroundStyle(Paleta.tinta)
                .multilineTextAlignment(.center)
            Text(text)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Paleta.tintaSuau)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Xip(text: "Prompte, prompte ✨", color: color)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .fonsMariapp()
        .onAppear { bota = !reduirMoviment }
    }
}

// MARK: - Dates en valencià

enum Dates {
    static let locale = Locale(identifier: "ca_ES")

    static func llarga(_ d: Date) -> String {
        d.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(locale))
    }

    static func curta(_ d: Date) -> String {
        d.formatted(.dateTime.day().month(.abbreviated).locale(locale))
    }

    static func hora(_ d: Date) -> String {
        d.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute().locale(locale))
    }

    static func mes(_ d: Date) -> String {
        d.formatted(.dateTime.month(.abbreviated).locale(locale))
    }

    static func mesLlarg(_ d: Date) -> String {
        d.formatted(.dateTime.month(.wide).year().locale(locale))
    }
}
