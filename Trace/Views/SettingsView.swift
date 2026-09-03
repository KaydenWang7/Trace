//
//  SettingsView.swift
//  Trace
//
//  Created by Kayden Wang on 3/25/26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("showGradient") private var showGradient: Bool = true
    @AppStorage("recordLocation") private var recordLocation: Bool = true
    @AppStorage("useMetricSystem") private var useMetricSystem: Bool = true
    @Environment(Store.self) private var store
    @State private var showingPaywallSheet = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var showClearDataAlert = false
    @State private var showConfirmDialog = false
    @State private var confirmText = ""
    @State private var showingOnboarding = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Trace Pro") {
                    if store.isPro {
                        HStack {
                            Image(systemName: "star.circle.fill")
                                .foregroundStyle(.tint)
                            Text("You are a Trace Pro member")
                        }
                    } else {
                        Button(action: {
                            showingPaywallSheet = true
                        }) {
                            HStack {
                                Image(systemName: "star.circle.fill")
                                Text("Unlock Trace Pro")
                            }
                            .foregroundStyle(.tint)
                        }
                    }
                }
                
                Section("Appearance") {
                    Toggle(isOn: $showGradient) {
                        Text("Show rating gradients")
                    }
                }
                
                Section("Units") {
                    Toggle(isOn: $useMetricSystem) {
                        Text("Use Metric System")
                    }
                }
                
                Section("Privacy") {
                    Toggle(isOn: $recordLocation) {
                        Text("Record Location")
                    }
                }
                
                Section("About") {
                    Button(action: {
                        showingOnboarding = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle")
                            Text("Replay Onboarding")
                        }
                        .foregroundStyle(.primary)
                    }
                    
                    Link(destination: URL(string: "https://kaydenwang7.github.io/")!) {
                        HStack {
                            Image(systemName: "lock.shield")
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("Terms of Use")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "mailto:theflightforge@gmail.com")!) {
                        HStack {
                            Image(systemName: "envelope")
                            Text("Contact Us")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://forms.gle/2HtzSU4CHhPKdrEC8")!) {
                        HStack {
                            Image(systemName: "ladybug")
                            Text("Submit a Bug or Suggestion")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showClearDataAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear All Data")
                        }
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("This will permanently delete all logs and entries. This action cannot be undone.")
                }
                
                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Clear All Data?", isPresented: $showClearDataAlert) {
                Button("Continue", role: .destructive) {
                    confirmText = ""
                    showConfirmDialog = true
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all logs and entries. This action cannot be undone.")
            }
            .alert("Type CONFIRM to proceed", isPresented: $showConfirmDialog) {
                TextField("Type CONFIRM", text: $confirmText)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("Delete Everything", role: .destructive) {
                    if confirmText.uppercased() == "CONFIRM" {
                        clearAllData()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {
                    confirmText = ""
                }
            } message: {
                Text("Type CONFIRM to permanently delete all data.")
            }
            .fullScreenCover(isPresented: $showingOnboarding) {
                OnboardingView()
            }
            .sheet(isPresented: $showingPaywallSheet) {
                PaywallView()
            }
        }
    }
    
    private func clearAllData() {
        do {
            let logs = try modelContext.fetch(FetchDescriptor<Log>())
            for log in logs {
                modelContext.delete(log)
            }
            try modelContext.save()
        } catch {
            print("[ClearData] ERROR: Failed to clear data: \(error)")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Log.self, Entry.self], inMemory: true)
}
