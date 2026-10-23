import SwiftUI
import UIKit

/// Full mushaf reader: one page at a time, 15 justified lines, streamed audio and optional tafsir.
struct MushafView: View {
    let startPage: Int

    @AppStorage("quran.tafsir") private var tafsirOn = false
    @AppStorage("quran.tafsirOpen") private var tafsirOpen = true
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
        // A column, not an overlay: the page shrinks to make room for the audio bar and tafsir.
        VStack(spacing: 0) {
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
            .frame(maxHeight: .infinity)

            bottomArea
        }
        .environment(\.layoutDirection, .rightToLeft)
        .background(Color.black.ignoresSafeArea())
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

    /// Reserved area under the page: keeps the page size stable whether or not audio is selected.
    @ViewBuilder
    private var bottomArea: some View {
        VStack(spacing: 8) {
            if let sel = player.selected {
                if tafsirOn {
                    tafsirCard
                }
                audioBar(sel)
            } else {
                Color.clear.frame(height: 68)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity)
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

    private var tafsirCard: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation { tafsirOpen.toggle() }
            } label: {
                HStack {
                    Text("التفسير · ابن كثير")
                        .font(Theme.font(13, weight: .medium))
                        .foregroundStyle(Theme.mint)
                    Spacer()
                    Text(tafsirOpen ? "إخفاء" : "إظهار")
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.secondaryText)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if tafsirOpen {
                ScrollView {
                    ArabicParagraph(
                        text: tafsirText ?? "جارٍ تحميل التفسير…",
                        fontName: "ReadexPro-Regular",
                        size: 15,
                        color: UIColor.white.withAlphaComponent(0.9)
                    )
                }
                .frame(maxHeight: 170)

                Text(TafsirService.attribution)
                    .font(Theme.font(11))
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 20)
    }

    private func audioBar(_ sel: AyahRef) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(reciter.name)
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.mint)
                Text("سورة \(QuranStore.shared.surah(sel.surah)?.name ?? "") · الآية \(arabicDigits(sel.ayah))")
                    .font(Theme.font(11))
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer(minLength: 4)
            HStack(spacing: 10) {
                controlButton("chevron.right", size: 44, label: "الآية السابقة") {
                    player.step(-1, reciter: reciter)
                }
                Button {
                    player.togglePlay(reciter: reciter)
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 54)
                        .glassCard(cornerRadius: 27)
                }
                .accessibilityLabel(player.isPlaying ? "إيقاف مؤقت" : "تشغيل")
                controlButton("chevron.left", size: 44, label: "الآية التالية") {
                    player.step(1, reciter: reciter)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassCard(cornerRadius: 26)
    }

    private func controlButton(_ symbol: String, size: CGFloat, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.mint)
                .frame(width: size, height: size)
                .glassCard(cornerRadius: size / 2)
        }
        .accessibilityLabel(label)
    }
}

/// Arabic paragraph shown through UIKit with forced right-to-left direction and word wrapping.
/// This avoids the reversed-looking rendering seen with SwiftUI Text for long Arabic blocks.
private struct ArabicParagraph: UIViewRepresentable {
    let text: String
    let fontName: String
    let size: CGFloat
    let color: UIColor

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        label.semanticContentAttribute = .forceRightToLeft
        let style = NSMutableParagraphStyle()
        style.alignment = .right
        style.baseWritingDirection = .rightToLeft
        style.lineSpacing = 6
        let font = UIFont(name: fontName, size: size) ?? UIFont.systemFont(ofSize: size)
        label.attributedText = NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: style
        ])
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView label: UILabel, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0 else { return nil }
        return label.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    }
}

/// One mushaf page: a header, 15 justified text lines, and a footer.
struct MushafPageView: View {
    let page: MushafPage
    let basmala: String
    let selected: AyahRef?
    let onTap: (AyahRef) -> Void

    private static let baseSize: CGFloat = 20
    private static let sidePadding: CGFloat = 14

    /// One word, plus its ayah medallion when the word ends the verse.
    private struct Unit {
        let word: String
        let ref: AyahRef
        let mark: Int?
    }

    var body: some View {
        GeometryReader { geo in
            let size = fontSize(for: geo.size)
            let lineWidth = max(geo.size.width - Self.sidePadding * 2, 100)
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
                    lineView(line, size: size, width: lineWidth)
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
            .padding(.horizontal, Self.sidePadding)
            .padding(.top, 6)
            .padding(.bottom, 2)
        }
    }

    /// One size per page: the widest line fills the width, so every line fits.
    private func fontSize(for size: CGSize) -> CGFloat {
        let availW = max(size.width - Self.sidePadding * 2, 100)
        let availH = max(size.height - 6 - 2 - 52, 100)
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
        let byWidth = 0.9 * Self.baseSize * availW / widest
        let byHeight = (availH / 15) / 1.6
        return min(max(min(byWidth, byHeight), 12), 36)
    }

    @ViewBuilder
    private func lineView(_ line: MushafLine, size: CGFloat, width: CGFloat) -> some View {
        switch line.k {
        case "t":
            textLine(line.items ?? [], size: size, width: width)
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

    /// Justified line: the gaps are equal and sit only between words, never inside a word or medallion.
    private func textLine(_ items: [MushafItem], size: CGFloat, width: CGFloat) -> some View {
        let units = makeUnits(items)
        let natural = units.reduce(CGFloat(0)) { $0 + unitWidth($1, size: size) }
        let gap = units.count > 1 ? max((width - natural) / CGFloat(units.count - 1) - 0.5, 0) : 0
        return HStack(spacing: gap) {
            ForEach(Array(units.enumerated()), id: \.offset) { _, unit in
                unitView(unit, size: size)
            }
        }
        .frame(width: width)
    }

    private func makeUnits(_ items: [MushafItem]) -> [Unit] {
        var result: [Unit] = []
        for item in items {
            let ref = AyahRef(surah: item.s, ayah: item.a)
            let words = item.t.split(separator: " ").map(String.init)
            for (index, word) in words.enumerated() {
                let isLast = index == words.count - 1
                result.append(Unit(word: word, ref: ref, mark: (isLast && item.e == 1) ? item.a : nil))
            }
        }
        return result
    }

    private func unitWidth(_ unit: Unit, size: CGFloat) -> CGFloat {
        let font = UIFont(name: "AmiriQuran-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
        var width = (unit.word as NSString).size(withAttributes: [.font: font]).width
        if unit.mark != nil {
            width += size * 1.25 + 4
        }
        return width
    }

    @ViewBuilder
    private func unitView(_ unit: Unit, size: CGFloat) -> some View {
        HStack(spacing: 4) {
            Text(unit.word)
                .font(.custom("AmiriQuran-Regular", size: size))
                .foregroundStyle(selected == unit.ref ? Theme.mint : Color.white)
                .lineLimit(1)
                .fixedSize()
                .contentShape(Rectangle())
                .onTapGesture { onTap(unit.ref) }
            if let number = unit.mark {
                medallion(number, size: size)
            }
        }
    }

    private func medallion(_ number: Int, size: CGFloat) -> some View {
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
