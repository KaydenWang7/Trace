import SwiftUI
import MapKit


struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var currentTab = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip") {
                    finishOnboarding()
                }
                .foregroundStyle(.secondary)
                .padding()
            }
            
            TabView(selection: $currentTab) {
                OnboardingPage(
                    title: "Welcome to Trace",
                    description: "Track, organize, and remember the things that matter most."
                ) {
                    Image(systemName: "pencil.and.list.clipboard")
                        .font(.system(size: 80))
                        .foregroundStyle(.tint)
                        .padding(.bottom, 20)
                }
                .tag(0)
                
                OnboardingPage(
                    title: "Create a Log",
                    description: "Group your related memories, tasks, or tracking items into distinct logs."
                ) {
                    LogMockup()
                }
                .tag(1)
                
                OnboardingPage(
                    title: "Make an Entry",
                    description: "Add text, photos, and location data to remember every detail."
                ) {
                    EntryMockup()
                }
                .tag(2)
                
                OnboardingPage(
                    title: "Swipe Gestures",
                    description: "Swipe left on a log to quickly add an entry."
                ) {
                    SwipeGestureMockup()
                }
                .tag(3)
                
                OnboardingPage(
                    title: "Interactive Maps",
                    description: "See your entries on an interactive map."
                ) {
                    MapMockup()
                }
                .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            Button(action: {
                if currentTab < 4 {
                    withAnimation {
                        currentTab += 1
                    }
                } else {
                    finishOnboarding()
                }
            }) {
                Text(currentTab == 0 ? "Get Started" : (currentTab < 4 ? "Next" : "Start Tracing"))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            .padding(.top, 20)
        }
    }
    
    private func finishOnboarding() {
        hasSeenOnboarding = true
        dismiss()
    }
}

struct OnboardingPage<Visual: View>: View {
    let visual: Visual
    let title: String
    let description: String
    
    init(title: String, description: String, @ViewBuilder visual: () -> Visual) {
        self.title = title
        self.description = description
        self.visual = visual()
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            visual
            
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding(.bottom, 70)
    }
}

#Preview {
    OnboardingView()
}

// MARK: - Mockups

struct MockupContainer<Content: View>: View {
    @ViewBuilder var content: Content
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .frame(height: 160)
            
            content
                .padding()
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 10)
    }
}

struct LogMockup: View {
    var body: some View {
        MockupContainer {
            HStack(spacing: 12) {
                Image(systemName: "airplane")
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Taipei Trip")
                        .font(.headline)
                    Text("4 entries")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
    }
}

struct EntryMockup: View {
    var body: some View {
        MockupContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Taipei 101")
                        .font(.headline)
                    Spacer()
                    Text("10:41 AM")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("The view from the top was absolutely incredible!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
    }
}

struct SwipeGestureMockup: View {
    @State private var offset: CGFloat = 0
    
    var body: some View {
        MockupContainer {
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 120, height: 72)
                        
                        VStack(spacing: 2) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Add")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(width: 80)
                    }
                    
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                HStack(spacing: 12) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.body)
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.orange, in: RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Coffee Shops")
                            .font(.headline)
                        Text("Just now")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                .offset(x: offset)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    offset = 80
                }
            }
        }
    }
}

struct MapMockup: View {
    var body: some View {
        MockupContainer {
            Map(interactionModes: []) {
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: 25.0339, longitude: 121.5644)) {
                    PinView(name: "Taipei 101")
                }
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: 25.0428, longitude: 121.5065)) {
                    PinView(name: "Ximending")
                }
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: 25.0780, longitude: 121.5262)) {
                    PinView(name: "Yuanshan")
                }
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: 25.0505, longitude: 121.5775)) {
                    PinView(name: "Raohe")
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
    }
}

struct PinView: View {
    let name: String
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(.red)
                .font(.title2)
                .background(Circle().fill(.white))
            
            Text(name)
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 4))
        }
    }
}
