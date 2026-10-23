import SwiftUI

struct NamesView: View {
    @AppStorage("textSize") private var textSize = 1

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private var scale: CGFloat {
        Theme.textScale(textSize)
    }

    var body: some View {
        ZStack {
            AmbientBackground(tint: Theme.mint)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(AllahNames.all.enumerated()), id: \.offset) { index, name in
                        VStack(spacing: 8) {
                            Text("\(index + 1)")
                                .font(Theme.font(13, scale: scale))
                                .foregroundStyle(Theme.secondaryText)
                            Text(name)
                                .font(Theme.font(22, weight: .bold, scale: scale))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity, minHeight: 96)
                        .glassCard(cornerRadius: 22)
                    }
                }
                .padding(20)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("أسماء الله الحسنى")
        .navigationBarTitleDisplayMode(.inline)
    }
}
