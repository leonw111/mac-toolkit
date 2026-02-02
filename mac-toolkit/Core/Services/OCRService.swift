//
//  OCRService.swift
//  mac-toolkit
//
//  OCR service implementation using Vision framework
//

import Foundation
import Vision
import CoreImage

actor OCRService {
    public static let shared = OCRService()

    private init() {}

    public func recognizeText(from image: Data) async throws -> String {
        guard let ciImage = CIImage(data: image) else {
            throw NSError(domain: "OCRService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }

        let processedImage = preprocessImage(ciImage)
        
        return try await withCheckedThrowingContinuation { continuation in
            recognizeTextFromCIImage(processedImage) { result in
                switch result {
                case .success(let text):
                    continuation.resume(returning: text)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func preprocessImage(_ image: CIImage) -> CIImage {
        let filteredImage = image.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0.0,
            kCIInputContrastKey: 1.5,
            kCIInputBrightnessKey: 0.1
        ])
        
        return filteredImage
    }

    private func recognizeTextFromCIImage(_ ciImage: CIImage, completion: @escaping (Result<String, Error>) -> Void) {
        let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        let request = VNRecognizeTextRequest {request, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(NSError(domain: "OCRService", code: -3, userInfo: [NSLocalizedDescriptionKey: "No text found"])))
                return
            }

            let recognizedStrings = observations.compactMap { observation -> String? in
                return observation.topCandidates(1).first?.string
            }

            if recognizedStrings.isEmpty {
                completion(.failure(NSError(domain: "OCRService", code: -4, userInfo: [NSLocalizedDescriptionKey: "No text recognized"])))
                return
            }

            let resultText = recognizedStrings.joined(separator: "\n")
            completion(.success(resultText))
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["zh-Hans", "en-US"]

        do {
            try requestHandler.perform([request])
        } catch {
            completion(.failure(error))
        }
    }

    public func getSupportedLanguages() -> [String] {
        return ["zh-Hans", "en-US"]
    }
    
    public func recognizeTextSync(from image: Data) throws -> String {
        guard let ciImage = CIImage(data: image) else {
            throw NSError(domain: "OCRService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }

        let processedImage = preprocessImage(ciImage)
        
        var result: Result<String, Error>?
        let semaphore = DispatchSemaphore(value: 0)
        
        recognizeTextFromCIImage(processedImage) { res in
            result = res
            semaphore.signal()
        }
        
        semaphore.wait()
        
        guard let finalResult = result else {
            throw NSError(domain: "OCRService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Recognition failed"])
        }
        
        switch finalResult {
        case .success(let text):
            return text
        case .failure(let error):
            throw error
        }
    }
}
