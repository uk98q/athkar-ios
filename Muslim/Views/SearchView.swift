import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("textSize") private var textSize = 1
    @State private var query = ""

    private struct Result: Identifiable {
        let id: String
        let text: String
        let source: String
    }

    private var scale: CGFloat {
        Theme.textScale(textSize)
    }

    private var results: [Result] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        var output: [Result] = []
        for category in AthkarCategory.allCases {
            for item in category.items where item.text.contains(q) {
                output.append(Result(id: category.rawValue + item.id, text: item.text, source: category.title))
            }
        }
        for name in AllahNames.all where name.contains(q) {
            output.append(Result(id: "name-" + name, text: name, source: "أسماء الله الحسنى"))
        }
        return output
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground(tint: Theme.mint)
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if query.trimmingCharacters(in: .whitespaces).isEmpty {
                            Text("اكتب كلمة مثل: الاستغفار، الصلاة، الرزق")
                                .font(Theme.font(15, scale: scale))
                                .foregroundStyle(Theme.secondaryText)
                                .padding(.top, 40)
                        } else if results.isEmpty {
                            Text("لا توجد نتائج")
                                .font(Theme.font(15, scale: scale))
                                .foregroundStyle(Theme.secondaryText)
                                .padding(.top, 40)
                        } else {
                            ForEach(results) { result in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(result.text)
                                        .font(Theme.font(16, weight: .medium, scale: scale))
                                        .foregroundStyle(.white)
                                        .lineLimit(4)
                                    Text(result.source)
                                        .font(Theme.font(12, scale: scale))
                                        .foregroundStyle(Theme.mint)
                                }
                                .multilineTextAlignment(.leading)
                                .padding(18)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .glassCard(cornerRadius: 22)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("بحث")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "ابحث في الأذكار والأسماء")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("إغلاق") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
