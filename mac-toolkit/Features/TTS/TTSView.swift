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
            Text("TTS - Text to Speech")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextEditor(text: $inputText)
                .font(.body)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .frame(minHeight: 150)

            HStack {
                Button("Speak") {
                    Task {
                        await speak()
                    }
                }
                .disabled(inputText.isEmpty || isSpeaking)

                Button("Stop") {
                    stop()
                }
                .disabled(!isSpeaking)

                Spacer()
            }

            if isSpeaking {
                ProgressView("Speaking...")
            }
        }
        .padding()
    }

    private func speak() async {
        isSpeaking = true
        defer { isSpeaking = false }

        do {
            try await SpeakService.shared.speak(text: inputText)
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }

    private func stop() {
        isSpeaking = false
        Task {
            await SpeakService.shared.stop()
        }
    }
}

#Preview {
    TTSView()
}
