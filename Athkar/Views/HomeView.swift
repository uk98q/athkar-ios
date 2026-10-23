import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: ProgressStore

    private var isMorning: Bool {
        Calendar.current.component(.hour, from: Date()) < 12
    }

    private var currentPeriod: Period {
        isMorning ? .morning : .evening
    }

    var body: some View {
        ZStack {
            AmbientBackground(tint: currentPeriod.accent)
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    ForEach(Period.allCases) { period in
                        NavigationLink(value: period) {
                            PeriodCard(period: period, progress: store.progress(period))
                        }
                        .buttonStyle(.plain)
                    }
                    Text("يتم حفظ التقدم على جهازك فقط")
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationDestination(for: Period.self) { period in
            PeriodListView(period: period)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(isMorning ? "صباح الخير" : "مساء الخير")
                .font(Theme.font(34, weight: .bold))
                .foregroundStyle(.white)
            Text(hijriDateText)
                .font(Theme.font(16))
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

struct PeriodCard: View {
    let period: Period
    let progress: Double

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(period.accent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: period.symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(period.accent)
            }
            .frame(width: 66, height: 66)

            VStack(alignment: .leading, spacing: 6) {
                Text(period.title)
                    .font(Theme.font(20, weight: .bold))
                    .foregroundStyle(.white)
                Text(period.subtitle)
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.secondaryText)
                Text(progressText)
                    .font(Theme.font(13, weight: .medium))
                    .foregroundStyle(period.accent)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.forward")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 30, interactive: true)
    }

    private var progressText: String {
        if progress >= 1 {
            return "تم إنجاز الذكر كله"
        }
        return "\(Int(progress * 100))% مكتمل"
    }
}
