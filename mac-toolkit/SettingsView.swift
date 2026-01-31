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
            Text("设置")
                .font(.largeTitle)
                .fontWeight(.bold)

            GroupBox("OCR 设置") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("识别语言")
                    Picker("", selection: $ocrLanguage) {
                        Text("简体中文").tag("zh-Hans")
                        Text("繁体中文").tag("zh-Hant")
                        Text("英语").tag("en-US")
                        Text("日语").tag("ja-JP")
                        Text("韩语").tag("ko-KR")
                    }
                    .labelsHidden()
                }
                .padding()
            }

            GroupBox("TTS 设置") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("语音语言")
                    Picker("", selection: $ttsLanguage) {
                        Text("中文").tag("zh-CN")
                        Text("英语").tag("en-US")
                        Text("日语").tag("ja-JP")
                    }
                    .labelsHidden()
                }
                .padding()
            }

            GroupBox("STT 设置") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("识别语言")
                    Picker("", selection: $sttLanguage) {
                        Text("中文").tag("zh-CN")
                        Text("英语").tag("en-US")
                        Text("日语").tag("ja-JP")
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
