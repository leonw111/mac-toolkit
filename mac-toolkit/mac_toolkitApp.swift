//
//  mac_toolkitApp.swift
//  mac-toolkit
//
//  Application entry point
//

import SwiftUI

@main
struct mac_toolkitApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
                .task {
                    // Start HTTP Server when app launches
                    do {
                        try await HTTPServer.shared.start()
                    } catch {
                        print("Failed to start HTTP Server: \(error)")
                    }
                }
                .onDisappear {
                    // Stop HTTP Server when app exits
                    Task {
                        await HTTPServer.shared.stop()
                    }
                }
        }
        .windowStyle(.automatic)
        .defaultSize(width: 900, height: 650)

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
