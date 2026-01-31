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
                .onAppear {
                    // Start HTTP Server when app launches
                    SimpleHTTPServer.shared.start()
                }
                .onDisappear {
                    // Stop HTTP Server when app exits
                    SimpleHTTPServer.shared.stop()
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
