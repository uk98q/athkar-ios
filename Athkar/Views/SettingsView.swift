import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: ProgressStore
    @AppStorage("textSize") private var textSize = 1
    @AppStorage("haptics") private var haptics = true
    @State private var showResetConfirm = false

    var body: some View {
        ZStack {
            AmbientBackground(tint: Theme.dusk)
            ScrollView {
                VStack(spacing: 18) {
                    section(title: "العرض") {
                        Picker("حجم الخط", selection: $textSize) {
                            Text("صغير").tag(0)
                            Text("متوسط").tag(1)
                            Text("كبير").tag(2)
                            Text("كبير جدًا").tag(3)
                        }
                        .pickerStyle(.segmented)
                    }

                    section(title: "التفاعل") {
                        Toggle("الاهتزاز عند العد", isOn: $haptics)
                            .font(Theme.font(16))
                            .foregroundStyle(.white)
                            .tint(Theme.mint)
                    }

                    section(title: "البيانات") {
                        Button {
                            showResetConfirm = true
                        } label: {
                            Text("تصفير تقدم اليوم")
                                .font(Theme.font(16, weight: .medium))
                                .foregroundStyle(Theme.dawn)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }

                    section(title: "عن التطبيق") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("أذكار: الإصدار 1.1")
                                .font(Theme.font(16, weight: .medium))
                                .foregroundStyle(.white)
                            Text("كل المزايا مجانية، ولا توجد اشتراكات أو مشتريات داخل التطبيق.")
                                .font(Theme.font(14))
                                .foregroundStyle(Theme.secondaryText)
                            Text("نصوص الأذكار مأخوذة من الأذكار المأثورة المشهورة، وينصح بمراجعتها من مصدر موثوق.")
                                .font(Theme.font(14))
                                .foregroundStyle(Theme.secondaryText)
                            Text("الخط: Readex Pro بترخيص SIL Open Font License 1.1.")
                                .font(Theme.font(14))
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(20)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("الإعدادات")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("تصفير تقدم اليوم؟", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("تصفير", role: .destructive) {
                store.resetToday()
            }
            Button("إلغاء", role: .cancel) {}
        }
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(Theme.font(14, weight: .bold))
                .foregroundStyle(Theme.secondaryText)
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 26)
    }
}
