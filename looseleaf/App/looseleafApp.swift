//
//  looseleafApp.swift
//  looseleaf
//
//  Created by Ivandohan Samuel Siregar on 18/06/26.
//

import SwiftUI

@main
struct looseleafApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

/// Shows the splash briefly, then crossfades into Home.
struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            HomeView()

            if showSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.4))
            withAnimation(.easeOut(duration: 0.4)) { showSplash = false }
        }
    }
}
