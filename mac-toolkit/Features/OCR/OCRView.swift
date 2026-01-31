//
//  OCRView.swift
//  mac-toolkit
//
//  OCR feature view
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct OCRView: View {
    @State private var selectedImage: NSImage?
    @State private var resultText: String = ""
    @State private var isProcessing: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text("OCR - 文字识别")
                .font(.largeTitle)
                .fontWeight(.bold)

            if let image = selectedImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
            } else {
                VStack {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("拖拽图片到这里或点击选择")
                        .foregroundColor(.gray)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .onTapGesture {
                    selectImage()
                }
            }

            if isProcessing {
                ProgressView("处理中...")
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
                Button("选择图片") {
                    selectImage()
                }
                .disabled(isProcessing)

                Button("识别文字") {
                    Task {
                        await performOCR()
                    }
                }
                .disabled(selectedImage == nil || isProcessing)

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

    private func selectImage() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]

        if panel.runModal() == .OK, let url = panel.url {
            selectedImage = NSImage(contentsOf: url)
        }
    }

    private func performOCR() async {
        isProcessing = true
        defer { isProcessing = false }

        guard let image = selectedImage, let tiffData = image.tiffRepresentation else {
            resultText = "错误: 无法获取图片数据"
            return
        }

        do {
            resultText = try await OCRService.shared.recognizeText(from: tiffData)
        } catch {
            resultText = "错误: \(error.localizedDescription)"
        }
    }

    private func copyResult() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(resultText, forType: .string)
    }
}

#Preview {
    OCRView()
}
