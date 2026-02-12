import Foundation
import UIKit
@preconcurrency import Vision

struct OCRTextBlock: Identifiable, Hashable {
    let id: UUID
    let text: String
    let boundingBox: CGRect

    init(id: UUID = UUID(), text: String, boundingBox: CGRect) {
        self.id = id
        self.text = text
        self.boundingBox = boundingBox
    }
}

struct OCRResult {
    let fullText: String
    let blocks: [OCRTextBlock]
}

protocol OCRServicing {
    func extractText(from image: UIImage) async throws -> OCRResult
}

final class OCRService: OCRServicing {
    func extractText(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw AppError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let blocks = observations.compactMap { observation -> OCRTextBlock? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    return OCRTextBlock(text: candidate.string, boundingBox: observation.boundingBox)
                }

                let text = blocks
                    .map(\.text)
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard !text.isEmpty else {
                    continuation.resume(throwing: AppError.noTextFound)
                    return
                }

                continuation.resume(returning: OCRResult(fullText: text, blocks: blocks))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: AppError.ocrFailed)
            }
        }
    }
}
