//
//  AppState.swift
//  mac-toolkit
//
//  Global application state
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()

    @Published var selectedTab: AppTab = .ocr
    @Published var isLoading: Bool = false

    private init() {}
}

enum AppTab: String, CaseIterable {
    case ocr = "OCR"
    case tts = "TTS"
    case stt = "STT"
    case settings = "Settings"
}
