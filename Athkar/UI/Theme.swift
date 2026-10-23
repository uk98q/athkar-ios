import SwiftUI

enum Theme {
    static let dawn = Color(red: 1.0, green: 0.74, blue: 0.52)
    static let dusk = Color(red: 0.70, green: 0.64, blue: 1.0)
    static let mint = Color(red: 0.52, green: 0.94, blue: 0.82)
    static let secondaryText = Color.white.opacity(0.62)

    /// Readex Pro (SIL Open Font License 1.1) is bundled as static instances.
    static func font(_ size: CGFloat, weight: FontWeight = .regular, scale: CGFloat = 1.0) -> Font {
        Font.custom(weight.postScriptName, size: size * scale)
    }

    /// Maps the Settings text-size level (0 small ... 3 extra large) to a multiplier.
    static func textScale(_ level: Int) -> CGFloat {
        switch level {
        case 0: return 0.9
        case 2: return 1.15
        case 3: return 1.3
        default: return 1.0
        }
    }
}

func progressLabel(_ progress: Double) -> String {
    if progress >= 1 {
        return "تم إنجاز القسم"
    }
    return "\(Int(progress * 100))% مكتمل"
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
    var tint: Color = Theme.dusk

    var body: some View {
        ZStack {
            Color.black
            Circle()
                .fill(tint.opacity(0.20))
                .frame(width: 340, height: 340)
                .blur(radius: 110)
                .offset(x: -130, y: -280)
            Circle()
                .fill(Theme.dusk.opacity(0.10))
                .frame(width: 300, height: 300)
                .blur(radius: 110)
                .offset(x: 150, y: 260)
        }
        .ignoresSafeArea()
    }
}

struct ProgressRing: View {
    let progress: Double
    let color: Color
    let symbol: String
    var size: CGFloat = 66

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 6)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: symbol)
                .font(.system(size: size * 0.32, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
    }
}
