import SwiftUI

extension View {
    /// Toggles `isCompact` based on vertical scroll offset. Uses the precise
    /// `onScrollGeometryChange` on iOS 18+, and is a no-op below (a preference
    /// fallback handles older versions).
    @ViewBuilder
    func scrollCompacts(_ isCompact: Binding<Bool>, threshold: CGFloat = 8) -> some View {
        if #available(iOS 18.0, *) {
            self.onScrollGeometryChange(for: Bool.self) { geo in
                geo.contentOffset.y > threshold
            } action: { _, compact in
                if compact != isCompact.wrappedValue {
                    withAnimation(.easeInOut(duration: 0.22)) { isCompact.wrappedValue = compact }
                }
            }
        } else {
            self
        }
    }
}
