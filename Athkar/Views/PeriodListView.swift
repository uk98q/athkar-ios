import SwiftUI
import UIKit

struct PeriodListView: View {
    let period: Period
    @EnvironmentObject private var store: ProgressStore

    var body: some View {
        ZStack {
            AmbientBackground(tint: period.accent)
            ScrollView {
                LazyVStack(spacing: 16) {
                    summary
                    ForEach(period.items) { item in
                        DhikrCard(period: period, dhikr: item)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle(period.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.resetPeriod(period)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
        }
    }

    private var summary: some View {
        let progress = store.progress(period)
        return VStack(alignment: .leading, spacing: 12) {
            Text(period.subtitle)
                .font(Theme.font(17, weight: .medium))
                .foregroundStyle(.white)
            ProgressView(value: progress)
                .tint(period.accent)
            Text("\(Int(progress * 100))% مكتمل")
                .font(Theme.font(13))
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 26)
    }
}

struct DhikrCard: View {
    let period: Period
    let dhikr: Dhikr
    @EnvironmentObject private var store: ProgressStore

    var body: some View {
        let count = store.count(period, dhikr.id)
        let done = count >= dhikr.target
        VStack(alignment: .leading, spacing: 18) {
            Text(dhikr.text)
                .font(Theme.font(20, weight: .medium))
                .foregroundStyle(.white)
                .lineSpacing(9)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                counterButton(count: count, done: done)
                Spacer(minLength: 8)
                Text("التكرار \(dhikr.target)")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 26)
        .opacity(done ? 0.6 : 1)
        .contextMenu {
            Button("إعادة هذا الذكر", systemImage: "arrow.counterclockwise") {
                store.resetItem(period, dhikr)
            }
        }
    }

    private func counterButton(count: Int, done: Bool) -> some View {
        Button {
            guard !done else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if count + 1 >= dhikr.target {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            store.tap(period, dhikr)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: done ? "checkmark.circle.fill" : "plus.circle.fill")
                Text("\(count) / \(dhikr.target)")
                    .font(Theme.font(16, weight: .bold))
                    .monospacedDigit()
            }
            .foregroundStyle(done ? Theme.success : period.accent)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Capsule().fill((done ? Theme.success : period.accent).opacity(0.16)))
        }
        .buttonStyle(.plain)
        .disabled(done)
    }
}
