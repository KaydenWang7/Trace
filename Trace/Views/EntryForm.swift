import SwiftUI

struct EntryForm: View {
    @Binding var timestamp: Date
    @Binding var title: String
    @Binding var rating: Double?
    @Binding var desc: String
    var onChange: () -> Void = {}

    private static let ratingFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimum = 0
        f.maximum = 10
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        f.alwaysShowsDecimalSeparator = false
        return f
    }()

    // A helper binding that shows empty when rating == nil, and parses user input back to Double?
    private var ratingTextBinding: Binding<String> {
        Binding<String>(
            get: { // convert Double? to String for display
                guard let rating else { return "" }
                return Self.ratingFormatter.string(from: NSNumber(value: rating)) ?? ""
            },
            set: { newValue in // convert String to Double?
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    rating = nil
                } else if let number = Self.ratingFormatter.number(from: trimmed)?.doubleValue {
                    let clamped = min(max(number, 0), 10)
                    let rounded = (clamped * 100).rounded() / 100
                    rating = rounded
                } else {
                    // Rating is unchanged
                }
                onChange()
            }
        )
    }

    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $title)
                    .textInputAutocapitalization(.sentences)
                    .onChange(of: title) { onChange() }

                DatePicker("Timestamp", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .onChange(of: timestamp) { onChange() }
            }

            Section("Rating") {
                HStack {
                    Text("Score")
                    Spacer()
                    TextField("0–10", text: ratingTextBinding)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 60)
                }
            }

            Section("Description") {
                TextEditor(text: $desc)
                    .frame(minHeight: 140)
                    .onChange(of: desc) { onChange() }
                    .textInputAutocapitalization(.sentences)
            }
        }
    }
}

