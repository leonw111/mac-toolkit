//
//  TTSView.swift
//  mac-toolkit
//
//  TTS feature view
//

import SwiftUI

struct TTSView: View {
    @State private var inputText: String = ""
    @State private var isSpeaking: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text("TTS - 文字转语音")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextEditor(text: $inputText)
                .font(.body)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .frame(minHeight: 150)

            HStack {
                Button("朗读") {
                    Task {
                        await speak()
                    }
                }
                .disabled(inputText.isEmpty || isSpeaking)

                Button("停止") {
                    stop()
                }
                .disabled(!isSpeaking)

                Spacer()
            }

            if isSpeaking {
                ProgressView("朗读中...")
            }
        }
        .padding()
    }

    private func speak() async {
        isSpeaking = true
        defer { isSpeaking = false }

        do {
            try await TTSService.shared.speak(text: inputText)
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }

    private func stop() {
        isSpeaking = false
    }
}

#Preview {
    TTSView()
}
