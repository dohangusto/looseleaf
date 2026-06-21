import SwiftUI

/// Branded launch splash shown briefly at app start, then fades into Home.
struct SplashView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 18) {
                logo
                    .scaleEffect(animate ? 1 : 0.7)
                    .opacity(animate ? 1 : 0)

                Text("Looseleaf")
                    .font(.largeTitle.bold())
                    .opacity(animate ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { animate = true }
        }
    }

    @ViewBuilder
    private var logo: some View {
        if let icon = Self.appIcon {
            Image(uiImage: icon)
                .resizable()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
        } else {
            Image(systemName: "leaf.fill")
                .font(.system(size: 76))
                .foregroundStyle(.blue)
        }
    }

    /// Best-effort load of the bundle's app icon for in-app display.
    private static let appIcon: UIImage? = {
        guard let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let files = primary["CFBundleIconFiles"] as? [String],
              let name = files.last else {
            return nil
        }
        return UIImage(named: name)
    }()
}

#Preview {
    SplashView()
}
