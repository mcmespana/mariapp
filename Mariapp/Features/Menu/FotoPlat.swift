import SwiftUI

/// Foto d'un plat dins de la plastilina: cantons arredonits i, mentre arriba (o si no n'hi ha), l'emoji sobre una boleta suau.
struct FotoPlat: View {
    let url: URL?
    var emoji: String = "🍲"
    var alcada: CGFloat = 120
    var color: Color = Paleta.verd

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: Clay.radiMitja, style: .continuous)
        AsyncImage(url: url, transaction: Transaction(animation: Clay.molla)) { fase in
            switch fase {
            case .success(let imatge):
                imatge
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            default:
                placeholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: alcada)
        .clipShape(forma)
        .overlay { forma.strokeBorder(Color.white.opacity(0.35), lineWidth: 1) }
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        Text(emoji)
            .font(.system(size: alcada * 0.42))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clay(color, radi: Clay.radiMitja, elevacio: 0.3)
    }
}
