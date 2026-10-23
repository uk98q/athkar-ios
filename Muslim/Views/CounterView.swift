import SwiftUI
import UIKit

struct CounterView: View {
    @AppStorage("counter.value") private var value = 0
    @AppStorage("counter.label") private var label = "عداد"
    @AppStorage("haptics") private var haptics = true

    var body: some View {
        ZStack {
            AmbientBackground(tint: Theme.dusk)
            VStack(spacing: 30) {
                TextField("اسم العداد", text: $label)
                    .font(Theme.font(18, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)
                    .glassCard(cornerRadius: 22)
                    .padding(.horizontal, 40)

                Text("\(value)")
                    .font(Theme.font(80, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                HStack(spacing: 22) {
                    circleButton(symbol: "minus", tint: Theme.secondaryText) {
                        if value > 0 { value -= 1 }
                        tickHaptic()
                    }
                    Button {
                        value += 1
                        tickHaptic()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 104, height: 104)
                            .background(Circle().fill(Theme.dusk))
                    }
                    .buttonStyle(.plain)
                    circleButton(symbol: "arrow.counterclockwise", tint: Theme.dawn) {
                        value = 0
                    }
                }

                Text("اضغط زر الزائد للعد، والناقص للتراجع")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(.bottom, 80)
        }
        .navigationTitle("العداد")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func circleButton(symbol: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 70, height: 70)
                .glassCard(cornerRadius: 35, interactive: true)
        }
        .buttonStyle(.plain)
    }

    private func tickHaptic() {
        guard haptics else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
