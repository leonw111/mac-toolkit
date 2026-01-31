//
//  STTView.swift
//  mac-toolkit
//
//  STT feature view
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct STTView: View {
    @State private var resultText: String = ""
    @State private var isRecording: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text("STT - 语音转文字")
                .font(.largeTitle)
                .fontWeight(.bold)

            if isRecording {
                VStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 60, height: 60)
                        .scaleEffect(isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording)

                    Text("录音中...")
                        .foregroundColor(.red)
                        .font(.headline)
                }
            } else {
                VStack {
                    Image(systemName: "waveform")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("点击开始录音")
                        .foregroundColor(.gray)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }

            if !resultText.isEmpty {
                ScrollView {
                    Text(resultText)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 200)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }

            HStack {
                Button(isRecording ? "停止录音" : "开始录音") {
                    Task {
                        await toggleRecording()
                    }
                }

                Spacer()

                if !resultText.isEmpty {
                    Button("复制") {
                        copyResult()
                    }
                }
            }
        }
        .padding()
    }

    private func toggleRecording() async {
        if isRecording {
            isRecording = false
            do {
                resultText = try await STTService.shared.transcribe(audio: Data())
            } catch {
                resultText = "错误: \(error.localizedDescription)"
            }
        } else {
            isRecording = true
            resultText = ""
        }
    }

    private func copyResult() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(resultText, forType: .string)
    }
}

#Preview {
    STTView()
}
