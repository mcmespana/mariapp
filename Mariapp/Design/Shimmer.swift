import SwiftUI

/// Brillantor que passa per damunt mentre es carrega alguna cosa.
struct Shimmer: ViewModifier {
    let actiu: Bool
    var radi: CGFloat = Clay.radiGran

    @State private var fase: CGFloat = -1
    @Environment(\.accessibilityReduceMotion) private var reduirMoviment

    func body(content: Content) -> some View {
        content
            .overlay {
                if actiu && !reduirMoviment {
                    GeometryReader { geo in
                        LinearGradient(colors: [.clear, Color.white.opacity(0.45), .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: geo.size.width * 0.6)
                            .offset(x: fase * geo.size.width)
                            .onAppear {
                                fase = -1
                                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) { fase = 1 }
                            }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: radi, style: .continuous))
                    .allowsHitTesting(false)
                }
            }
            .opacity(actiu && reduirMoviment ? 0.6 : 1)
    }
}

extension View {
    func shimmer(_ actiu: Bool, radi: CGFloat = Clay.radiGran) -> some View {
        modifier(Shimmer(actiu: actiu, radi: radi))
    }
}
