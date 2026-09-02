//
//  PaywallView.swift
//  Trace
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Store.self) private var store
    @State private var showingDemo = false
    @State private var isPurchasing = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header Image / Icon
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.tint)
                        .padding(.top, 40)
                    
                    VStack(spacing: 8) {
                        Text(store.products.first?.displayName ?? "Unlock Trace Pro")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(store.products.first?.description ?? "Get the most out of your logs with advanced features.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Features List
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(icon: "chart.bar.fill", title: "Advanced Statistics", description: "Visualize your habits with detailed charts and heatmaps.")
                        FeatureRow(icon: "photo.on.rectangle.angled", title: "Unlimited Photos", description: "Attach as many photos as you want to your entries.")
                        FeatureRow(icon: "map.fill", title: "Location Tracking", description: "See all your logs on a beautiful interactive map.")
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Demo Button
                    Button(action: {
                        showingDemo = true
                    }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("View Interactive Demo")
                        }
                        .font(.headline)
                        .foregroundColor(.accentColor)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.accentColor.opacity(0.15))
                        .cornerRadius(20)
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Purchase Button
                    VStack(spacing: 16) {
                        if let product = store.products.first {
                            Button(action: {
                                Task {
                                    isPurchasing = true
                                    try? await store.purchase(product)
                                    isPurchasing = false
                                    if store.isPro { dismiss() }
                                }
                            }) {
                                HStack {
                                    if isPurchasing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .padding(.trailing, 8)
                                    }
                                    Text("Unlock for \(product.displayPrice)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .cornerRadius(12)
                            }
                            .disabled(isPurchasing)
                        } else if store.isLoadingProducts {
                            ProgressView()
                                .padding()
                        } else {
                            VStack(spacing: 8) {
                                Text("Products Unavailable")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Text("Please run the app directly from Xcode to enable StoreKit testing.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        }
                        
                        Button(action: {
                            Task {
                                isPurchasing = true
                                await store.restorePurchases()
                                isPurchasing = false
                                if store.isPro { dismiss() }
                            }
                        }) {
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                        }
                        .disabled(isPurchasing)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray.opacity(0.5))
                    }
                }
            }
            .sheet(isPresented: $showingDemo) {
                LogStatsView(entries: Self.demoEntries)
            }
        }
    }
    
    private static let demoEntries: [Entry] = {
        var entries: [Entry] = []
        let calendar = Calendar.current
        let now = Date()
        
        // Generate exactly 365 entries for a dense heatmap
        for i in 0..<365 {
            let daysAgo = i
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
            
            // Randomly skip some days to create small gaps
            if Double.random(in: 0...1) > 0.8 { continue }
            
            // Bias rating towards higher numbers
            let rating = Double.random(in: 4...10)
            
            let hasLocation = Bool.random()
            let hasPhoto = Bool.random()
            
            // Generate locations around SF with varying spread
            let latOffset = Double.random(in: -0.5...0.5)
            let lonOffset = Double.random(in: -0.5...0.5)
            
            let entry = Entry(
                timestamp: date,
                title: "Demo Entry \(i)",
                rating: rating,
                desc: "This is a sample entry for the demo.",
                photoData: hasPhoto ? Data() : nil,
                latitude: hasLocation ? (37.7749 + latOffset) : nil,
                longitude: hasLocation ? (-122.4194 + lonOffset) : nil
            )
            entries.append(entry)
        }
        return entries
    }()
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    PaywallView()
}
