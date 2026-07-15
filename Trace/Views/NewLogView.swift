import SwiftUI

struct NewLogView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    var onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Log title", text: $title)
            }
            .navigationTitle("New Log")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed)
                        dismiss()
                    }
                }
            }
        }
    }
}
