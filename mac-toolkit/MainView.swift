//
//  MainView.swift
//  mac-toolkit
//
//  Main view with tab navigation
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            OCRView()
                .tabItem {
                    Label("OCR", systemImage: "doc.text.viewfinder")
                }
                .tag(AppTab.ocr)

            TTSView()
                .tabItem {
                    Label("TTS", systemImage: "speaker.wave.2")
                }
                .tag(AppTab.tts)

            STTView()
                .tabItem {
                    Label("STT", systemImage: "waveform")
                }
                .tag(AppTab.stt)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    MainView()
        .environmentObject(AppState.shared)
}
