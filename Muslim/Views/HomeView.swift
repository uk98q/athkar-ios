import SwiftUI

enum AppRoute: Hashable {
    case category(AthkarCategory)
    case names
    case tasbih
    case counter
    case settings
    case quran
    case quranSurah(Int)
}

struct HomeSection: Identifiable {
    let id: String
    let route: AppRoute
    let title: String
    let subtitle: String
    let symbol: String
    let color: Color
}

struct HomeView: View {
    @EnvironmentObject private var store: ProgressStore
    @EnvironmentObject private var location: LocationService
    @AppStorage("textSize") private var textSize = 1

    @State private var path = NavigationPath()
    @State private var showSearch = false

    private let gridColumns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    private var scale: CGFloat {
        Theme.textScale(textSize)
    }

    private var sections: [HomeSection] {
        [
            HomeSection(id: "morning", route: .category(.morning), title: "أذكار الصباح",
                        subtitle: progressLabel(store.progress(.morning)), symbol: "sun.max.fill", color: Theme.dawn),
            HomeSection(id: "evening", route: .category(.evening), title: "أذكار المساء",
                        subtitle: progressLabel(store.progress(.evening)), symbol: "moon.fill", color: Theme.dusk),
            HomeSection(id: "afterPrayer", route: .category(.afterPrayer), title: "بعد الصلاة",
                        subtitle: progressLabel(store.progress(.afterPrayer)), symbol: "checkmark.seal.fill", color: Theme.mint),
            HomeSection(id: "sleep", route: .category(.sleep), title: "أذكار النوم",
                        subtitle: progressLabel(store.progress(.sleep)), symbol: "bed.double.fill", color: Theme.dusk),
            HomeSection(id: "wakeUp", route: .category(.wakeUp), title: "عند الاستيقاظ",
                        subtitle: progressLabel(store.progress(.wakeUp)), symbol: "alarm.fill", color: Theme.dawn),
            HomeSection(id: "names", route: .names, title: "أسماء الله الحسنى",
                        subtitle: "\(AllahNames.all.count) اسمًا", symbol: "star.fill", color: Theme.mint),
            HomeSection(id: "quran", route: .quran, title: "القرآن الكريم",
                        subtitle: "النص والتفسير والتلاوة", symbol: "book.fill", color: Theme.mint),
            HomeSection(id: "tasbih", route: .tasbih, title: "المسبحة",
                        subtitle: "عدّ بالتسبيح والتحميد", symbol: "hand.tap.fill", color: Theme.dawn),
            HomeSection(id: "counter", route: .counter, title: "العداد",
                        subtitle: "عداد حر لأي ذكر", symbol: "number.circle.fill", color: Theme.dusk)
        ]
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AmbientBackground(tint: Theme.dusk)
                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {
                       topBar
                       PrayerHeader(scale: scale)
                        DailyCard(scale: scale)
                        featuredCarousel
                        Text("الأقسام")
                            .font(Theme.font(18, weight: .bold, scale: scale))
                            .foregroundStyle(.white)
                        LazyVGrid(columns: gridColumns, spacing: 14) {
                            ForEach(sections) { section in
                                Button {
                                    path.append(section.route)
                                } label: {
                                    SectionTile(section: section, scale: scale)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Button {
                            path.append(AppRoute.settings)
                        } label: {
                            settingsRow
                        }
                        .buttonStyle(.plain)
                        Text("كل المزايا مجانية، والتقدم يُحفظ على جهازك فقط")
                            .font(Theme.font(13, scale: scale))
                            .foregroundStyle(Theme.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AppRoute.self) { route in
                destination(for: route)
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
        }
        .onAppear {
            location.start()
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .category(let category):
            CategoryView(category: category)
        case .names:
            NamesView()
        case .tasbih:
            TasbihView()
        case .counter:
            CounterView()
        case .settings:
            SettingsView()
        case .quran:
            QuranIndexView()
        case .quranSurah(let number):
            MushafView(startPage: MushafStore.shared.startPage(of: number))
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Image("SunriseLogo")
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                )
                .accessibilityHidden(true)
            Text("مسلم")
                .font(Theme.font(20, weight: .bold, scale: scale))
                .foregroundStyle(.white)
            Button {
                path.append(AppRoute.settings)
            } label: {
                GlassIcon(symbol: "gearshape.fill")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("الإعدادات")

            Spacer(minLength: 0)

            Button {
                showSearch = true
            } label: {
                GlassIcon(symbol: "magnifyingglass")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("بحث")

            Menu {
                Button {
                    path.append(AppRoute.category(.travel))
                } label: {
                    Label("دعاء السفر", systemImage: "airplane")
                }
                Button {
                    path.append(AppRoute.category(.duas))
                } label: {
                    Label("أدعية متنوعة", systemImage: "sparkles")
                }
            } label: {
                GlassIcon(symbol: "ellipsis")
            }
            .accessibilityLabel("القائمة")
        }
    }

    // MARK: - Wide cards

    private var featuredCarousel: some View {
        let dayIndex = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let dua = DailyContent.dua().text
        let name = AllahNames.all[dayIndex % AllahNames.all.count]
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                Button {
                    path.append(AppRoute.category(.morning))
                } label: {
                    FeatureCard(eyebrow: "الصباح", title: "أذكار الصباح",
                                detail: progressLabel(store.progress(.morning)),
                                symbol: "sun.max.fill", color: Theme.dawn, scale: scale)
                }
                .buttonStyle(.plain)

                Button {
                    path.append(AppRoute.category(.evening))
                } label: {
                    FeatureCard(eyebrow: "المساء", title: "أذكار المساء",
                                detail: progressLabel(store.progress(.evening)),
                                symbol: "moon.fill", color: Theme.dusk, scale: scale)
                }
                .buttonStyle(.plain)

                Button {
                    path.append(AppRoute.category(.duas))
                } label: {
                    FeatureCard(eyebrow: "دعاء اليوم", title: "من الأدعية المأثورة",
                                detail: dua, symbol: "sparkles", color: Theme.mint, scale: scale)
                }
                .buttonStyle(.plain)

                Button {
                    path.append(AppRoute.names)
                } label: {
                    FeatureCard(eyebrow: "اسم اليوم", title: name,
                                detail: "من أسماء الله الحسنى", symbol: "star.fill", color: Theme.mint, scale: scale)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal, -20)
    }

    private var settingsRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.dusk)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.dusk.opacity(0.16)))
            VStack(alignment: .leading, spacing: 3) {
                Text("الإعدادات")
                    .font(Theme.font(17, weight: .bold, scale: scale))
                    .foregroundStyle(.white)
                Text("الخط والاهتزاز والموقع")
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

// MARK: - Prayer header

struct PrayerHeader: View {
    @EnvironmentObject private var location: LocationService
    let scale: CGFloat

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let coordinate = location.effectiveCoordinate
            let todays = PrayerCalculator.times(on: now, latitude: coordinate.latitude, longitude: coordinate.longitude)
            let next = PrayerCalculator.next(after: now, latitude: coordinate.latitude, longitude: coordinate.longitude)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(hijriDate(now))
                        .font(Theme.font(20, weight: .bold, scale: scale))
                        .foregroundStyle(.white)
                    Text(gregorianDate(now))
                        .font(Theme.font(15, scale: scale))
                        .foregroundStyle(Theme.secondaryText)
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("الوقت المتبقي على \(next?.name ?? "")")
                                .font(Theme.font(14, weight: .medium, scale: scale))
                                .foregroundStyle(Theme.mint)
                            Text(countdown(next.map { $0.date.timeIntervalSince(now) } ?? 0))
                                .font(Theme.font(34, weight: .bold, scale: scale))
                                .monospacedDigit()
                                .foregroundStyle(.white)
                        }
                        Spacer(minLength: 0)
                    }

                    HStack(spacing: 6) {
                        ForEach(todays.filter { $0.id != "sunrise" }) { prayer in
                            VStack(spacing: 4) {
                                Text(prayer.name)
                                    .font(Theme.font(11, scale: scale))
                                    .foregroundStyle(Theme.secondaryText)
                                Text(clock(prayer.date))
                                    .font(Theme.font(13, weight: .medium, scale: scale))
                                    .foregroundStyle(prayer.id == next?.id ? Theme.mint : .white)
                                    .monospacedDigit()
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(cornerRadius: 28)

                Text(location.hasLocation
                     ? "أوقات الصلاة محسوبة على موقعك الحالي"
                     : "أوقات الصلاة تقريبية لمكة المكرمة، وتتغير عند السماح بالموقع")
                    .font(Theme.font(12, scale: scale))
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    private func hijriDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar_SA")
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func gregorianDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar_SA")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func clock(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

    private func countdown(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Components

struct GlassIcon: View {
    let symbol: String

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .glassCard(cornerRadius: 22, interactive: true)
    }
}

struct FeatureCard: View {
    let eyebrow: String
    let title: String
    let detail: String
    let symbol: String
    let color: Color
    let scale: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(eyebrow, systemImage: symbol)
                .font(Theme.font(13, weight: .medium, scale: scale))
                .foregroundStyle(color)
            Spacer(minLength: 0)
            Text(title)
                .font(Theme.font(20, weight: .bold, scale: scale))
                .foregroundStyle(.white)
                .lineLimit(2)
            Text(detail)
                .font(Theme.font(14, scale: scale))
                .foregroundStyle(Theme.secondaryText)
                .lineLimit(3)
        }
        .multilineTextAlignment(.leading)
        .padding(20)
        .frame(width: 280, height: 176, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(LinearGradient(colors: [color.opacity(0.32), Color.black], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .glassCard(cornerRadius: 30, interactive: true)
    }
}

struct SectionTile: View {
    let section: HomeSection
    let scale: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: section.symbol)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(section.color)
            Spacer(minLength: 0)
            Text(section.title)
                .font(Theme.font(16, weight: .bold, scale: scale))
                .foregroundStyle(.white)
                .lineLimit(2)
            Text(section.subtitle)
                .font(Theme.font(12, scale: scale))
                .foregroundStyle(Theme.secondaryText)
                .lineLimit(2)
        }
        .multilineTextAlignment(.leading)
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .glassCard(cornerRadius: 26, interactive: true)
    }
}
