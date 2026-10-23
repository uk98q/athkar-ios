import SwiftUI

struct QuranSurahView: View {
    let number: Int

    @AppStorage("quran.tafsir") private var tafsirOn = false
    @AppStorage("quran.reciter") private var reciterRaw = 0
    @AppStorage("textSize") private var textSize = 1

    @StateObject private var player = AyahPlayer()
    @State private var tafsir: [Int: TafsirLoad] = [:]
    @State private var expanded: Set<Int> = []

    private enum TafsirLoad {
        case loading
        case done(String)
        case failed
    }

    private var scale: CGFloat { Theme.textScale(textSize) }
    private var reciter: Reciter { Reciter.from(reciterRaw) }
    private var surah: QuranSurah? { QuranStore.shared.surah(number) }

    var body: some View {
        ZStack {
            AmbientBackground(tint: Theme.mint)
            if let surah {
                content(surah)
            } else {
                Text("تعذّر تحميل السورة")
                    .font(Theme.font(16))
                    .foregroundStyle(.white)
            }
        }
        .navigationTitle("سورة \(surah?.name ?? "")")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { player.stop() }
    }

    @ViewBuilder
    private func content(_ surah: QuranSurah) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(0..<surah.ayahCount, id: \.self) { i in
                        ayahCard(surah: surah, index: i)
                            .id(i)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 150)
            }
            .onChange(of: player.index) { _, newValue in
                withAnimation {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            playerBar(surah)
        }
    }

    private func ayahCard(surah: QuranSurah, index i: Int) -> some View {
        let ayahNo = i + 1
        let isCurrent = player.surah?.number == surah.number && player.index == i
        let isPlayingThis = isCurrent && player.isPlaying
        return VStack(alignment: .leading, spacing: 14) {
            Text(surah.ayahs[i])
                .font(Theme.font(24, scale: scale))
                .foregroundStyle(.white)
                .lineSpacing(10)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                Text(arabicDigits(ayahNo))
                    .font(Theme.font(13, weight: .bold, scale: scale))
                    .foregroundStyle(Theme.mint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Theme.mint.opacity(0.14)))

                Button {
                    togglePlayAyah(i)
                } label: {
                    Image(systemName: isPlayingThis ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Theme.mint))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("استماع للآية \(ayahNo)")

                if tafsirOn {
                    Button {
                        toggleTafsir(surah: surah, ayah: ayahNo)
                    } label: {
                        Text(expanded.contains(ayahNo) ? "إخفاء التفسير" : "التفسير")
                            .font(Theme.font(13, weight: .medium, scale: scale))
                            .foregroundStyle(Theme.dusk)
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }

            if tafsirOn, expanded.contains(ayahNo) {
                tafsirView(surah: surah, ayah: ayahNo)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 24)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(isCurrent ? Theme.mint.opacity(0.7) : Color.clear, lineWidth: 1.5)
        )
    }

    @ViewBuilder
    private func tafsirView(surah: QuranSurah, ayah: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            switch tafsir[ayah] ?? .loading {
            case .done(let text):
                Text(text)
                    .font(Theme.font(15, scale: scale))
                    .foregroundStyle(.white.opacity(0.88))
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(TafsirService.attribution)
                    .font(Theme.font(11))
                    .foregroundStyle(Theme.secondaryText)
            case .failed:
                Text("تعذّر تحميل التفسير الآن.")
                    .font(Theme.font(14, scale: scale))
                    .foregroundStyle(Theme.secondaryText)
                Button {
                    load(surah: surah, ayah: ayah)
                } label: {
                    Text("إعادة المحاولة")
                        .font(Theme.font(14, weight: .medium, scale: scale))
                        .foregroundStyle(Theme.mint)
                }
                .buttonStyle(.plain)
            case .loading:
                ProgressView()
                    .tint(Theme.mint)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.top, 4)
    }

    private func playerBar(_ surah: QuranSurah) -> some View {
        let active = player.surah?.number == surah.number
        let shown = active ? player.index : 0
        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("الآية \(arabicDigits(shown + 1)) من \(arabicDigits(surah.ayahCount))")
                    .font(Theme.font(15, weight: .bold, scale: scale))
                    .foregroundStyle(.white)
                Text(reciter.name)
                    .font(Theme.font(12, scale: scale))
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)

            Button {
                if active { player.previous(reciter: reciter) }
            } label: {
                Text("السابقة")
                    .font(Theme.font(14, weight: .medium, scale: scale))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .glassCard(cornerRadius: 18, interactive: true)
            }
            .buttonStyle(.plain)

            Button {
                if active {
                    player.togglePlay(reciter: reciter)
                } else {
                    player.play(surah: surah, ayahIndex: 0, reciter: reciter)
                }
            } label: {
                Image(systemName: active && player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Theme.mint))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("تشغيل أو إيقاف")

            Button {
                if active { player.next(reciter: reciter) }
            } label: {
                Text("التالية")
                    .font(Theme.font(14, weight: .medium, scale: scale))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .glassCard(cornerRadius: 18, interactive: true)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .glassCard(cornerRadius: 28)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func togglePlayAyah(_ i: Int) {
        guard let surah else { return }
        if player.surah?.number == surah.number && player.index == i {
            player.togglePlay(reciter: reciter)
        } else {
            player.play(surah: surah, ayahIndex: i, reciter: reciter)
        }
    }

    private func toggleTafsir(surah: QuranSurah, ayah: Int) {
        if expanded.contains(ayah) {
            expanded.remove(ayah)
            return
        }
        expanded.insert(ayah)
        if let existing = tafsir[ayah], case .done = existing {
            return
        }
        load(surah: surah, ayah: ayah)
    }

    private func load(surah: QuranSurah, ayah: Int) {
        tafsir[ayah] = .loading
        Task {
            do {
                let text = try await TafsirService.shared.text(surah: surah.number, ayah: ayah)
                tafsir[ayah] = .done(text)
            } catch {
                tafsir[ayah] = .failed
            }
        }
    }
}
