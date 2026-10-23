import SwiftUI

struct AdhkarIndexView: View {
    @EnvironmentObject private var store: ProgressStore
    @AppStorage("textSize") private var textSize = 1

    private var scale: CGFloat {
        Theme.textScale(textSize)
    }

    var body: some View {
        ZStack {
            AmbientBackground(tint: Theme.dusk)
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(AthkarCategory.allCases) { category in
                        NavigationLink {
                            CategoryView(category: category)
                        } label: {
                            IndexRow(
                                symbol: category.symbol,
                                color: category.accent,
                                title: category.title,
                                subtitle: progressLabel(store.progress(category)),
                                scale: scale
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    NavigationLink {
                        NamesView()
                    } label: {
                        IndexRow(
                            symbol: "star.fill",
                            color: Theme.mint,
                            title: "أسماء الله الحسنى",
                            subtitle: "\(AllahNames.all.count) اسمًا",
                            scale: scale
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("الأذكار")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct IndexRow: View {
    let symbol: String
    let color: Color
    let title: String
    let subtitle: String
    let scale: CGFloat

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(Circle().fill(color.opacity(0.16)))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.font(17, weight: .bold, scale: scale))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(Theme.font(13, scale: scale))
                    .foregroundStyle(Theme.secondaryText)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.forward")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 24, interactive: true)
    }
}
