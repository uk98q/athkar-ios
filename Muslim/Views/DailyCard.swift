import SwiftUI

/// Home card for "آية اليوم" and "دعاء اليوم". The tafsir opens inside the card and
/// pushes the content below it down, so it never covers other content.
struct DailyCard: View {
    let scale: CGFloat

    @State private var showTafsir = false
    @State private var tafsir: String?
    @State private var tafsirState: LoadState = .idle

    private let verse = DailyContent.verse()
    private let dua = DailyContent.dua()

    private enum LoadState {
        case idle, loading, loaded, failed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("اليوم")
                .font(Theme.font(13, weight: .medium, scale: scale))
                .foregroundStyle(Theme.mint)

            // Verse of the day
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("آية اليوم")
                        .font(Theme.font(17, weight: .bold, scale: scale))
                        .foregroundStyle(.white)
                    Spacer(minLength: 0)
                    Text("\(verse.surahName) · الآية \(arabicDigits(verse.ayah))")
                        .font(Theme.font(12, scale: scale))
                        .foregroundStyle(Theme.secondaryText)
                }

                Text(verse.text)
                    .font(.custom("AmiriQuran-Regular", size: 24 * scale))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(10)
                    .frame(maxWidth: .infinity)

                Button {
                    toggleTafsir()
                } label: {
                    HStack(spacing: 6) {
                        Text(showTafsir ? "إخفاء التفسير" : "عرض التفسير")
                            .font(Theme.font(14, weight: .medium, scale: scale))
                        Image(systemName: showTafsir ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Theme.mint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)

                if showTafsir {
                    tafsirPanel
                }
            }

            Divider().overlay(Color.white.opacity(0.1))

            // Dua of the day
            VStack(alignment: .leading, spacing: 8) {
                Text("دعاء اليوم")
                    .font(Theme.font(17, weight: .bold, scale: scale))
                    .foregroundStyle(.white)
                Text(dua.text)
                    .font(Theme.font(17, scale: scale))
                    .foregroundStyle(.white)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("المصدر: \(dua.source)")
                    .font(Theme.font(12, scale: scale))
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 28)
        .environment(\.layoutDirection, .rightToLeft)
    }

    @ViewBuilder
    private var tafsirPanel: some View {
        VStack(alignment: .trailing, spacing: 8) {
            switch tafsirState {
            case .idle, .loading:
                HStack(spacing: 8) {
                    ProgressView().tint(Theme.mint)
                    Text("جارٍ تحميل التفسير")
                        .font(Theme.font(14, scale: scale))
                        .foregroundStyle(Theme.secondaryText)
                }
                .frame(maxWidth: .infinity)
            case .failed:
                Text("تعذّر تحميل التفسير. تحقق من الاتصال بالإنترنت ثم حاول مرة أخرى.")
                    .font(Theme.font(14, scale: scale))
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            case .loaded:
                ScrollView {
                    Text(tafsir ?? "")
                        .font(Theme.font(15, scale: scale))
                        .foregroundStyle(.white)
                        .lineSpacing(6)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxHeight: 240)
            }
            Text(TafsirService.attribution)
                .font(Theme.font(11, scale: scale))
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func toggleTafsir() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showTafsir.toggle()
        }
        guard showTafsir, tafsirState != .loaded, tafsirState != .loading else { return }
        tafsirState = .loading
        let surah = verse.surah
        let ayah = verse.ayah
        Task {
            do {
                let text = try await TafsirService.shared.text(surah: surah, ayah: ayah)
                await MainActor.run {
                    tafsir = text
                    tafsirState = .loaded
                }
            } catch {
                await MainActor.run {
                    tafsirState = .failed
                }
            }
        }
    }
}
