import SwiftUI

@main
struct MarineRoutePlanApp: App {
    @StateObject private var appState = AppState()
    @State private var showLaunch = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showLaunch {
                    LaunchView(isFinished: $showLaunch)
                        .transition(.opacity)
                } else if !appState.hasCompletedOnboarding {
                    OnboardingView()
                        .environmentObject(appState)
                        .transition(.opacity)
                } else if !appState.isLoggedIn {
                    AuthView()
                        .environmentObject(appState)
                        .transition(.opacity)
                } else {
                    MainTabView()
                        .environmentObject(appState)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: showLaunch)
            .animation(.easeInOut(duration: 0.3), value: appState.hasCompletedOnboarding)
            .animation(.easeInOut(duration: 0.3), value: appState.isLoggedIn)
            .preferredColorScheme(appState.colorScheme)
        }
    }
}
