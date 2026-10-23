import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: ProgressStore
    @EnvironmentObject private var location: LocationService
    @AppStorage("textSize") private var textSize = 1
    @AppStorage("haptics") private var haptics = true
    @AppStorage("quran.reciter") private var reciterRaw = 0
    @AppStorage("quran.tafsir") private var tafsirOn = false
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

                    section(title: "القرآن الكريم") {
                        VStack(alignment: .leading, spacing: 14) {
                            Picker("القارئ", selection: $reciterRaw) {
                                ForEach(Reciter.allCases) { reciter in
                                    Text(reciter.name).tag(reciter.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Theme.mint)
                            Toggle("إظهار زر التفسير لكل آية", isOn: $tafsirOn)
                                .font(Theme.font(16))
                                .foregroundStyle(.white)
                                .tint(Theme.mint)
                            Text("التفسير: تفسير ابن كثير عبر quran.com. الصوت يُبث من everyayah.com عند الاستماع فقط، ولا يُحفظ على الجهاز.")
                                .font(Theme.font(13))
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    section(title: "الموقع وأوقات الصلاة") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(location.hasLocation
                                 ? "الأوقات محسوبة على موقعك الحالي، ولا يُرسل الموقع إلى أي خادم."
                                 : "لم يُسمح بالموقع بعد، لذلك الأوقات محسوبة لمكة المكرمة.")
                                .font(Theme.font(14))
                                .foregroundStyle(Theme.secondaryText)
                            Button {
                                location.start()
                            } label: {
                                Text("تحديث الموقع")
                                    .font(Theme.font(16, weight: .medium))
                                    .foregroundStyle(Theme.mint)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                            Text("مسلم: الإصدار 1.4")
                                .font(Theme.font(16, weight: .medium))
                                .foregroundStyle(.white)
                            Text("نص القرآن: مشروع تنزيل Tanzil.net، رواية حفص عن عاصم، برخصة CC BY 3.0.")
                                .font(Theme.font(14))
                                .foregroundStyle(Theme.secondaryText)
                            Text("التفسير: تفسير ابن كثير (ت 774هـ) عبر واجهة quran.com.")
                                .font(Theme.font(14))
                                .foregroundStyle(Theme.secondaryText)
                            Text("كل المزايا مجانية، ولا توجد اشتراكات أو مشتريات داخل التطبيق.")
                                .font(Theme.font(14))
                                .foregroundStyle(Theme.secondaryText)
                            Text("نصوص الأذكار من الأذكار المأثورة المشهورة، وينصح بمراجعتها من مصدر موثوق.")
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
