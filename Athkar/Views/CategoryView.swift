import SwiftUI
import UIKit

struct CategoryView: View {
    let category: AthkarCategory
    @EnvironmentObject private var store: ProgressStore
    @AppStorage("textSize") private var textSize = 1
    @AppStorage("haptics") private var haptics = true

    private var scale: CGFloat {
        Theme.textScale(textSize)
    }

    var body: some View {
        ZStack {
            AmbientBackground(tint: category.accent)
            ScrollView {
                LazyVStack(spacing: 16) {
                    summary
                    ForEach(category.items) { item in
                        DhikrCard(category: category, dhikr: item, scale: scale, haptics: haptics)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.resetCategory(category)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .accessibilityLabel("تصفير القسم")
            }
        }
    }

    private var summary: some View {
        let progress = store.progress(category)
        return VStack(alignment: .leading, spacing: 12) {
            Text(category.subtitle)
                .font(Theme.font(17, weight: .medium, scale: scale))
                .foregroundStyle(.white)
            ProgressView(value: progress)
                .tint(category.accent)
            Text(progressLabel(progress))
                .font(Theme.font(13, scale: scale))
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 26)
    }
}

struct DhikrCard: View {
    let category: AthkarCategory
    let dhikr: Dhikr
    let scale: CGFloat
    let haptics: Bool

    @EnvironmentObject private var store: ProgressStore

    var body: some View {
        let count = store.count(category, dhikr.id)
        let done = count >= dhikr.target
        VStack(alignment: .leading, spacing: 18) {
            Text(dhikr.text)
                .font(Theme.font(20, weight: .medium, scale: scale))
                .foregroundStyle(.white)
                .lineSpacing(9)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                counterButton(count: count, done: done)
                Spacer(minLength: 8)
                Text("التكرار \(dhikr.target)")
                    .font(Theme.font(14, scale: scale))
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 26)
        .opacity(done ? 0.6 : 1)
        .contextMenu {
            Button("إعادة هذا الذكر", systemImage: "arrow.counterclockwise") {
                store.resetItem(category, dhikr)
            }
        }
    }

    private func counterButton(count: Int, done: Bool) -> some View {
        let tint = done ? Theme.mint : category.accent
        return Button {
            guard !done else { return }
            if haptics {
                if count + 1 >= dhikr.target {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
            store.tap(category, dhikr)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: done ? "checkmark.circle.fill" : "plus.circle.fill")
                Text("\(count) / \(dhikr.target)")
                    .font(Theme.font(16, weight: .bold, scale: scale))
                    .monospacedDigit()
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Capsule().fill(tint.opacity(0.16)))
        }
        .buttonStyle(.plain)
        .disabled(done)
    }
}
