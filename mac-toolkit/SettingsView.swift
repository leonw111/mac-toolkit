//
//  SettingsView.swift
//  mac-toolkit
//
//  Settings view
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("ocrLanguage") private var ocrLanguage: String = "zh-Hans"
    @AppStorage("ttsLanguage") private var ttsLanguage: String = "zh-CN"
    @AppStorage("sttLanguage") private var sttLanguage: String = "zh-CN"

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)

            GroupBox("OCR Settings") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recognition Language")
                    Picker("", selection: $ocrLanguage) {
                        Text("Simplified Chinese").tag("zh-Hans")
                        Text("Traditional Chinese").tag("zh-Hant")
                        Text("English").tag("en-US")
                        Text("Japanese").tag("ja-JP")
                        Text("Korean").tag("ko-KR")
                    }
                    .labelsHidden()
                }
                .padding()
            }

            GroupBox("TTS Settings") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Speech Language")
                    Picker("", selection: $ttsLanguage) {
                        Text("Chinese").tag("zh-CN")
                        Text("English").tag("en-US")
                        Text("Japanese").tag("ja-JP")
                    }
                    .labelsHidden()
                }
                .padding()
            }

            GroupBox("STT Settings") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recognition Language")
                    Picker("", selection: $sttLanguage) {
                        Text("Chinese").tag("zh-CN")
                        Text("English").tag("en-US")
                        Text("Japanese").tag("ja-JP")
                    }
                    .labelsHidden()
                }
                .padding()
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    SettingsView()
}
