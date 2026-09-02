//
//  EntryForm.swift
//  Trace
//
//  Created by Kayden Wang on 2/4/26.
//

import SwiftUI
import PhotosUI
import MapKit

struct EntryForm: View {
    @Binding var timestamp: Date
    @Binding var title: String
    @Binding var rating: Double?
    @Binding var desc: String
    @Binding var photoData: Data?
    @Binding var latitude: Double?
    @Binding var longitude: Double?
    @Binding var locationName: String?
    
    var onChange: () -> Void = {}
    var titleFocused: FocusState<Bool>.Binding
    var isNewEntry: Bool = false
    
    @AppStorage("recordLocation") private var recordLocation: Bool = true
    @State private var showingLocationEditor = false

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

    @State private var selectedItem: PhotosPickerItem? = nil

    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $title)
                    .textInputAutocapitalization(.sentences)
                    .focused(titleFocused)
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

            Section("Photo") {
                VStack(alignment: .leading, spacing: 12) {
                    if let data = photoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Text("No photo")
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 20) {
                        if photoData == nil {
                            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                            }
                        } else {
                            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                            }

                            Button {
                                photoData = nil
                                selectedItem = nil
                                onChange()
                            } label: {
                                Image(systemName: "trash")
                                    .font(.title2)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onChange(of: selectedItem) { oldValue, newValue in
                        guard let newItem = newValue else { return }
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self) {
                                photoData = data
                                onChange()
                            }
                            selectedItem = nil
                        }
                    }
                }
            }
            
            if recordLocation && !isNewEntry {
                Section("Location") {
                    if let lat = latitude, let lon = longitude {
                        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        VStack(alignment: .leading) {
                            Map(initialPosition: .region(MKCoordinateRegion(
                                center: coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                            ))) {
                                Marker(locationName ?? "Location", coordinate: coordinate)
                            }
                            .id("\(lat),\(lon)")
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .allowsHitTesting(false)
                            .mapControlVisibility(.hidden)
                            .onTapGesture {
                                showingLocationEditor = true
                            }
                            
                            HStack {
                                Button("Edit Location") {
                                    showingLocationEditor = true
                                }
                                .font(.subheadline)
                                .buttonStyle(.borderless)
                                
                                Spacer()
                                
                                Button(role: .destructive) {
                                    latitude = nil
                                    longitude = nil
                                    locationName = nil
                                    onChange()
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.top, 8)
                        }
                    } else {
                        Button {
                            showingLocationEditor = true
                        } label: {
                            Label("Add Location", systemImage: "location.badge.plus")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingLocationEditor) {
            LocationEditorView(latitude: Binding(get: { latitude }, set: { latitude = $0; onChange() }),
                               longitude: Binding(get: { longitude }, set: { longitude = $0; onChange() }),
                               locationName: Binding(get: { locationName }, set: { locationName = $0; onChange() }))
        }
    }
}
