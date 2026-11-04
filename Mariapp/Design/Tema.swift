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
            .background(Paleta.fons.ignoresSafeArea())
    }
}

extension View {
    func fonsMariapp() -> some View { modifier(FonsMariapp()) }
}

// MARK: - Targeta

/// La peça bàsica: un paper crema amb vores molt arrodonides i ombra suau.
struct Targeta<Contingut: View>: View {
    var tint: Color? = nil
    @ViewBuilder var contingut: Contingut

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            contingut
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Paleta.paper)
                .overlay {
                    if let tint {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(LinearGradient(colors: [tint.opacity(0.10), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                }
                .shadow(color: Color.black.opacity(0.05), radius: 14, y: 6)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Paleta.linia.opacity(0.6), lineWidth: 0.5)
        }
    }
}

/// Capçalera d'una targeta: icona en una pastilla de color + títol + (opcional) alguna cosa a la dreta.
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
        HStack(spacing: 10) {
            Image(systemName: icona)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(titol)
                .font(.titolTargeta)
                .foregroundStyle(Paleta.tinta)
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

/// Botó suau: fons del color molt clar, text del color.
struct BotoSuau: ButtonStyle {
    var color: Color = Paleta.aigua
    var ple: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(ple ? Color.white : color)
            .background(ple ? color : color.opacity(0.14), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BotoSuau {
    static func suau(_ color: Color, ple: Bool = false) -> BotoSuau { BotoSuau(color: color, ple: ple) }
}

/// Botó rodó petit (+ / −).
struct BotoRodo: View {
    let icona: String
    let color: Color
    let accio: () -> Void

    var body: some View {
        Button(action: accio) {
            Image(systemName: icona)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 40, height: 40)
        }
        .buttonStyle(BotoRodoEstil(color: color))
    }
}

private struct BotoRodoEstil: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(color)
            .background(color.opacity(0.14), in: Circle())
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

// MARK: - Xips

struct Xip: View {
    let text: String
    var color: Color = Paleta.tintaSuau
    var seleccionat: Bool = false

    var body: some View {
        Text(text)
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(seleccionat ? .white : color)
            .background(seleccionat ? color : color.opacity(0.12), in: Capsule())
    }
}

// MARK: - Placeholder bonic per a seccions encara per fer

struct EnConstruccio: View {
    let emoji: String
    let titol: String
    let text: String
    var color: Color = Paleta.groc

    @State private var bota = false

    var body: some View {
        VStack(spacing: 18) {
            Text(emoji)
                .font(.system(size: 72))
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
        .onAppear { bota = true }
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
