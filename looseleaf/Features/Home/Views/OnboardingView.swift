import SwiftUI

/// A lightweight first-run welcome screen highlighting key features.
struct OnboardingView: View {
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            Image(systemName: "leaf.fill")
                .font(.system(size: 52))
                .foregroundStyle(.blue)
                .padding(.bottom, 12)

            Text("Welcome to Looseleaf")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("Your flexible writing canvas.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 22) {
                feature("square.and.pencil", "Capture anything",
                        "Mix text, images, quotes, vocabulary, voice notes, and expense tables on one page.")
                feature("rectangle.stack", "Multi-page notes",
                        "Each card holds several pages — swipe or tap the chevrons to move between them.")
                feature("magnifyingglass", "Find fast",
                        "Search across all your notes, or find content within a single page.")
                feature("paintbrush", "Make it yours",
                        "Dark mode, font size, and contrast live in the appearance menu.")
            }
            .padding(.top, 32)
            .padding(.horizontal, 8)

            Spacer()

            Button(action: onDone) {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .interactiveDismissDisabled()
    }

    private func feature(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    OnboardingView(onDone: {})
}
