import SwiftUI

/// Full mushaf reader: one page at a time, 15 justified lines, streamed audio and optional tafsir.
struct MushafView: View {
    let startPage: Int

    @AppStorage("quran.tafsir") private var tafsirOn = false
    @AppStorage("quran.reciter") private var reciterRaw = 0
    @StateObject private var player = MushafPlayer()
    @State private var page: Int
    @State private var tafsirText: String?

    init(startPage: Int) {
        self.startPage = startPage
        _page = State(initialValue: startPage)
    }

    private var reciter: Reciter { Reciter.from(reciterRaw) }
    private var basmala: String { QuranStore.shared.surah(1)?.ayahs.first ?? "" }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()
            TabView(selection: $page) {
                ForEach(MushafStore.shared.pages) { p in
                    MushafPageView(
                        page: p,
                        basmala: basmala,
                        selected: player.selected,
                        onTap: { player.select($0) }
                    )
                    .tag(p.n)
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)

            if let sel = player.selected {
                playerBar(sel)
            }
        }
        .navigationTitle("المصحف")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: player.loaded) { _, newValue in
            guard let ref = newValue else { return }
            let target = MushafStore.shared.page(of: ref.surah, ayah: ref.ayah)
            if target != page {
                withAnimation { page = target }
            }
        }
        .task(id: player.selected) {
            await loadTafsir()
        }
        .onDisappear { player.stop() }
    }

    private func loadTafsir() async {
        tafsirText = nil
        guard tafsirOn, let sel = player.selected else { return }
        do {
            tafsirText = try await TafsirService.shared.text(surah: sel.surah, ayah: sel.ayah)
        } catch {
            tafsirText = "تعذّر تحميل التفسير الآن. تحقق من الاتصال ثم أعد المحاولة."
        }
    }

    private func playerBar(_ sel: AyahRef) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(reciter.name)
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.mint)
                Spacer()
                Text("سورة \(QuranStore.shared.surah(sel.surah)?.name ?? "") · الآية \(arabicDigits(sel.ayah))")
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.secondaryText)
            }
            HStack(spacing: 18) {
                controlButton("forward.end.fill", label: "الآية السابقة") {
                    player.step(-1, reciter: reciter)
                }
                Button {
                    player.togglePlay(reciter: reciter)
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .glassCard(cornerRadius: 30)
                }
                .accessibilityLabel(player.isPlaying ? "إيقاف مؤقت" : "تشغيل")
                controlButton("backward.end.fill", label: "الآية التالية") {
                    player.step(1, reciter: reciter)
                }
            }
            if tafsirOn {
                ScrollView {
                    Text(tafsirText ?? "جارٍ تحميل التفسير…")
                        .font(Theme.font(14))
                        .foregroundStyle(.white.opacity(0.88))
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxHeight: 170)
                Text(TafsirService.attribution)
                    .font(Theme.font(11))
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 24)
        .padding(12)
    }

    private func controlButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.mint)
                .frame(width: 48, height: 48)
                .glassCard(cornerRadius: 24)
        }
        .accessibilityLabel(label)
    }
}

/// One mushaf page: a header, 15 justified text lines, and a footer.
struct MushafPageView: View {
    let page: MushafPage
    let basmala: String
    let selected: AyahRef?
    let onTap: (AyahRef) -> Void

    private static let baseSize: CGFloat = 20

    private enum Piece {
        case word(String, AyahRef)
        case mark(Int)
    }

    var body: some View {
        GeometryReader { geo in
            let size = fontSize(for: geo.size)
            VStack(spacing: 0) {
                HStack {
                    Text(MushafStore.shared.juzName(for: page))
                        .font(Theme.font(12))
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                    Text("سورة \(QuranStore.shared.surah(page.leadSurah)?.name ?? "")")
                        .font(Theme.font(13, weight: .medium))
                        .foregroundStyle(.white)
                }
                .frame(height: 26)

                ForEach(Array(page.lines.enumerated()), id: \.offset) { _, line in
                    lineView(line, size: size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                HStack {
                    Text("\(arabicDigits(page.q))/٤ الحزب \(arabicDigits(page.hizb))")
                        .font(Theme.font(12))
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                    Text(arabicDigits(page.n))
                        .font(Theme.font(12))
                        .foregroundStyle(Theme.secondaryText)
                }
                .frame(height: 26)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
        }
    }

    /// One size per page: the widest line fills the width, so every line is justified.
    private func fontSize(for size: CGSize) -> CGFloat {
        let availW = max(size.width - 28, 100)
        let availH = max(size.height - 12 - 52, 100)
        let base = UIFont(name: "AmiriQuran-Regular", size: Self.baseSize)
            ?? UIFont.systemFont(ofSize: Self.baseSize)
        var widest: CGFloat = 1
        for line in page.lines where line.k == "t" {
            let items = line.items ?? []
            let text = items.map { $0.t }.joined(separator: " ")
            let width = (text as NSString).size(withAttributes: [.font: base]).width
            let medallions = CGFloat(items.filter { $0.e == 1 }.count) * 1.25 * Self.baseSize
            widest = max(widest, width + medallions)
        }
        let byWidth = Self.baseSize * availW / widest
        let byHeight = (availH / 15) / 1.6
        return min(max(min(byWidth, byHeight), 12), 36)
    }

    @ViewBuilder
    private func lineView(_ line: MushafLine, size: CGFloat) -> some View {
        switch line.k {
        case "t":
            textLine(line.items ?? [], size: size)
        case "s":
            Text("سورة \(QuranStore.shared.surah(line.surah ?? 0)?.name ?? "")")
                .font(Theme.font(size * 0.7, weight: .medium))
                .foregroundStyle(Theme.mint)
                .padding(.horizontal, 18)
                .padding(.vertical, 2)
                .glassCard(cornerRadius: 14)
        case "b":
            Text(basmala)
                .font(.custom("AmiriQuran-Regular", size: size * 0.9))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        default:
            Color.clear
        }
    }

    private func textLine(_ items: [MushafItem], size: CGFloat) -> some View {
        let pieces = makePieces(items)
        return HStack(spacing: 0) {
            ForEach(Array(pieces.enumerated()), id: \.offset) { index, piece in
                if index > 0 { Spacer(minLength: 0) }
                pieceView(piece, size: size)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func makePieces(_ items: [MushafItem]) -> [Piece] {
        var result: [Piece] = []
        for item in items {
            let ref = AyahRef(surah: item.s, ayah: item.a)
            for word in item.t.split(separator: " ") {
                result.append(.word(String(word), ref))
            }
            if item.e == 1 {
                result.append(.mark(item.a))
            }
        }
        return result
    }

    @ViewBuilder
    private func pieceView(_ piece: Piece, size: CGFloat) -> some View {
        switch piece {
        case .word(let word, let ref):
            Text(word)
                .font(.custom("AmiriQuran-Regular", size: size))
                .foregroundStyle(selected == ref ? Theme.mint : Color.white)
                .lineLimit(1)
                .fixedSize()
                .contentShape(Rectangle())
                .onTapGesture { onTap(ref) }
        case .mark(let number):
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.55), lineWidth: 0.9)
                Text(arabicDigits(number))
                    .font(Theme.font(size * 0.42))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .lineLimit(1)
                    .fixedSize()
            }
            .frame(width: size * 1.25, height: size * 1.25)
        }
    }
}
