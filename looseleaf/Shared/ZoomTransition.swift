import SwiftUI

/// Zoom navigation transition helpers that gracefully no-op before iOS 18.
extension View {
    @ViewBuilder
    func zoomSource(id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            self.matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    @ViewBuilder
    func zoomDestination(id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            self.navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }

    /// Applies a zoom source only when a namespace is provided.
    @ViewBuilder
    func zoomSourceIfPresent(id: some Hashable, in namespace: Namespace.ID?) -> some View {
        if let namespace {
            zoomSource(id: id, in: namespace)
        } else {
            self
        }
    }
}
