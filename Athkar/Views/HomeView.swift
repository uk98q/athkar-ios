import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: ProgressStore
    @AppStorage("textSize") private var textSize = 1

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    private var isMorning: Bool {
        Calendar.current.component(.hour, from: Date()) < 12
    }

    private var suggested: AthkarCategory {
        isMorning ? .morning : .evening
    }

    private var scale: CGFloat {
        Theme.textScale(textSize)
    }

    var body: some View {
        ZStack {
            AmbientBackground(tint: suggested.accent)
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    NavigationLink {
                        CategoryView(category: suggested)
                    } label: {
                        SuggestedCard(category: suggested, progress: store.progress(suggested), scale: scale)
                    }
                    .buttonStyle(.plain)

                    Text("الأقسام")
                        .font(Theme.font(18, weight: .bold, scale: scale))
                        .foregroundStyle(.white)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(AthkarCategory.allCases) { category in
                            NavigationLink {
                                CategoryView(category: category)
                            } label: {
                                CategoryTile(category: category, progress: store.progress(category), scale: scale)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("يتم حفظ التقدم على جهازك فقط")
                        .font(Theme.font(13, scale: scale))
                        .foregroundStyle(Theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(isMorning ? "صباح الخير" : "مساء الخير")
                .font(Theme.font(34, weight: .bold, scale: scale))
                .foregroundStyle(.white)
            Text(hijriDateText)
                .font(Theme.font(16, scale: scale))
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var hijriDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar_SA")
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }
}

struct SuggestedCard: View {
    let category: AthkarCategory
    let progress: Double
    let scale: CGFloat

    var body: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("مقترح الآن")
                    .font(Theme.font(13, weight: .medium, scale: scale))
                    .foregroundStyle(category.accent)
                Text(category.title)
                    .font(Theme.font(22, weight: .bold, scale: scale))
                    .foregroundStyle(.white)
                Text(progressLabel(progress))
                    .font(Theme.font(14, scale: scale))
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer(minLength: 0)
            ProgressRing(progress: progress, color: category.accent, symbol: category.symbol, size: 72)
            Image(systemName: "chevron.forward")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 30, interactive: true)
    }
}

struct CategoryTile: View {
    let category: AthkarCategory
    let progress: Double
    let scale: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: category.symbol)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(category.accent)
            Spacer(minLength: 0)
            Text(category.title)
                .font(Theme.font(16, weight: .bold, scale: scale))
                .foregroundStyle(.white)
                .lineLimit(2)
            Text(progressLabel(progress))
                .font(Theme.font(13, scale: scale))
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .glassCard(cornerRadius: 26, interactive: true)
    }
}
