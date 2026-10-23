import SwiftUI

struct QuranIndexView: View {
    @State private var query = ""

    private var filtered: [QuranSurah] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return QuranStore.shared.surahs }
        return QuranStore.shared.surahs.filter { $0.name.contains(q) || String($0.number) == q }
    }

    var body: some View {
        ZStack {
            AmbientBackground(tint: Theme.mint)
            ScrollView {
                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Theme.secondaryText)
                        TextField("ابحث باسم السورة أو رقمها", text: $query)
                            .font(Theme.font(16))
                            .foregroundStyle(.white)
                    }
                    .padding(16)
                    .glassCard(cornerRadius: 22)

                    LazyVStack(spacing: 10) {
                        ForEach(filtered) { surah in
                            NavigationLink(value: AppRoute.quranSurah(surah.number)) {
                                SurahRow(surah: surah)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("نص القرآن: مشروع تنزيل Tanzil.net، رواية حفص عن عاصم، برخصة CC BY 3.0")
                        .font(Theme.font(12))
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                }
                .padding(20)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("القرآن الكريم")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SurahRow: View {
    let surah: QuranSurah

    var body: some View {
        HStack(spacing: 14) {
            Text(arabicDigits(surah.number))
                .font(Theme.font(15, weight: .bold))
                .foregroundStyle(Theme.mint)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.mint.opacity(0.14)))
            VStack(alignment: .leading, spacing: 3) {
                Text("سورة \(surah.name)")
                    .font(Theme.font(17, weight: .bold))
                    .foregroundStyle(.white)
                Text("\(arabicDigits(surah.ayahCount)) آية · \(surah.revelationLabel)")
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.backward")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 22, interactive: true)
    }
}
