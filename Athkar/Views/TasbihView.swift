import SwiftUI
import UIKit

struct TasbihView: View {
    @AppStorage("tasbih.count") private var count = 0
    @AppStorage("tasbih.total") private var total = 0
    @AppStorage("tasbih.target") private var target = 33
    @AppStorage("haptics") private var haptics = true

    private let presets = [33, 99, 100, 0]

    var body: some View {
        ZStack {
            AmbientBackground(tint: Theme.mint)
            VStack(spacing: 28) {
                Picker("الهدف", selection: $target) {
                    ForEach(presets, id: \.self) { value in
                        Text(value == 0 ? "بدون هدف" : "\(value)").tag(value)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)

                Button(action: tap) {
                    VStack(spacing: 8) {
                        Text("\(count)")
                            .font(Theme.font(64, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                        Text(target == 0 ? "بدون هدف" : "من \(target)")
                            .font(Theme.font(16))
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .frame(width: 240, height: 240)
                    .glassCard(cornerRadius: 120, interactive: true)
                }
                .buttonStyle(.plain)

                Text("اضغط الدائرة للعد")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.secondaryText)

                HStack(spacing: 16) {
                    Text("الإجمالي: \(total)")
                        .font(Theme.font(15, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .glassCard(cornerRadius: 22)

                    Button {
                        count = 0
                    } label: {
                        Text("تصفير العداد")
                            .font(Theme.font(15, weight: .medium))
                            .foregroundStyle(Theme.mint)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .glassCard(cornerRadius: 22, interactive: true)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 80)
        }
        .navigationTitle("المسبحة")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tap() {
        // After reaching the target, the next tap starts a new round.
        if target > 0 && count >= target {
            count = 0
        }
        count += 1
        total += 1
        guard haptics else { return }
        if target > 0 && count == target {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
