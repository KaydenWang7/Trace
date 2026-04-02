import SwiftUI

struct EntryForm: View {
    @Binding var timestamp: Date
    @Binding var title: String
    @Binding var rating: Double?
    var onChange: () -> Void = {}

    private static let ratingFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimum = 0
        f.maximum = 10
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
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
        List {
            DatePicker("Timestamp", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .controlSize(.regular)
                .onChange(of: timestamp) { onChange() }

            HStack {
                Text("Title")
                Spacer()
                TextField("Title", text: $title)
                    .onChange(of: title) { onChange() }
            }

            HStack {
                Text("Rating")
                Spacer()
                TextField("Rating", text: ratingTextBinding)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 60)
            }
        }
    }
}

