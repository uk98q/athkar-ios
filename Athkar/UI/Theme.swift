import SwiftUI

enum Theme {
    static let morningAccent = Color(red: 1.0, green: 0.80, blue: 0.45)
    static let eveningAccent = Color(red: 0.56, green: 0.68, blue: 1.0)
    static let success = Color(red: 0.45, green: 0.92, blue: 0.68)
    static let secondaryText = Color.white.opacity(0.62)

    /// Readex Pro (SIL Open Font License 1.1) is bundled as static instances.
    static func font(_ size: CGFloat, weight: FontWeight = .regular) -> Font {
        Font.custom(weight.postScriptName, size: size)
    }
}

enum FontWeight {
    case regular
    case medium
    case bold

    var postScriptName: String {
        switch self {
        case .regular: return "ReadexPro-Regular"
        case .medium: return "ReadexPro-Medium"
        case .bold: return "ReadexPro-Bold"
        }
    }
}

/// Liquid glass on iOS 26+, with a material fallback on older systems.
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 28
    var interactive: Bool = false

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26.0, *) {
            if interactive {
                content.glassEffect(Glass.regular.interactive(), in: shape)
            } else {
                content.glassEffect(Glass.regular, in: shape)
            }
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.stroke(Color.white.opacity(0.14), lineWidth: 1))
        }
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 28, interactive: Bool = false) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, interactive: interactive))
    }
}

/// Pure black base (OLED friendly) with soft colored light behind the glass.
struct AmbientBackground: View {
    var tint: Color = Theme.eveningAccent

    var body: some View {
        ZStack {
            Color.black
            Circle()
                .fill(tint.opacity(0.22))
                .frame(width: 340, height: 340)
                .blur(radius: 110)
                .offset(x: -130, y: -280)
            Circle()
                .fill(Theme.eveningAccent.opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 110)
                .offset(x: 150, y: 260)
        }
        .ignoresSafeArea()
    }
}
