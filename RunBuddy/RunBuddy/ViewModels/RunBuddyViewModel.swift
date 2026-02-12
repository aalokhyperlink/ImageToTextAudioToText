import Foundation
import UIKit

@MainActor
final class RunBuddyViewModel: ObservableObject {
    @Published var extractedText = ""
    @Published var transcribedText = ""
    @Published var translatedText = ""
    @Published var selectedImage: UIImage?
    @Published var ocrBlocks: [OCRTextBlock] = []
    @Published var selectedOCRBlockIDs: Set<UUID> = []
    @Published var useManualOCRSelection = true
    @Published var selectedLanguageCode: String
    @Published private(set) var availableLanguages: [TranslationLanguage]

    @Published var isExtractingText = false
    @Published var isTranscribing = false
    @Published var isTranslating = false
    @Published var isRecording = false

    @Published var showError = false
    @Published var errorMessage = ""

    private let ocrService: OCRServicing
    private let speechService: SpeechTranscribing
    private let translationService: Translating

    init(
        ocrService: OCRServicing = OCRService(),
        speechService: SpeechTranscribing = SpeechRecognitionService(),
        translationService: Translating = TranslationService()
    ) {
        self.ocrService = ocrService
        self.speechService = speechService
        self.translationService = translationService
        let languages = TranslationLanguage.allOptions
        availableLanguages = languages
        selectedLanguageCode = languages.contains(where: { $0.code == "hi" }) ? "hi" : (languages.first?.code ?? "en")
    }

    func preparePermissions() async {
        do {
            try await speechService.requestPermissions()
        } catch {
            presentError(error)
        }
    }

    func handlePickedImage(_ image: UIImage) async {
        selectedImage = image
        extractedText = ""
        ocrBlocks = []
        selectedOCRBlockIDs = []
        isExtractingText = true
        defer { isExtractingText = false }

        do {
            let result = try await ocrService.extractText(from: image)
            extractedText = result.fullText
            ocrBlocks = result.blocks
        } catch {
            presentError(error)
        }
    }

    func toggleOCRBlock(_ id: UUID) {
        if selectedOCRBlockIDs.contains(id) {
            selectedOCRBlockIDs.remove(id)
        } else {
            selectedOCRBlockIDs.insert(id)
        }
    }

    func clearSelectedOCRBlocks() {
        selectedOCRBlockIDs.removeAll()
    }

    func selectAllOCRBlocks() {
        selectedOCRBlockIDs = Set(ocrBlocks.map(\.id))
    }

    func copySelectedOCRText() {
        let selectedText = selectedOCRText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !selectedText.isEmpty else {
            presentError(AppError.noSelectedText)
            return
        }
        UIPasteboard.general.string = selectedText
    }

    var selectedOCRText: String {
        ocrBlocks
            .filter { selectedOCRBlockIDs.contains($0.id) }
            .map(\.text)
            .joined(separator: "\n")
    }

    func startRecording() async {
        do {
            try await speechService.requestPermissions()
            isTranscribing = true
            try speechService.startRecording { [weak self] partial in
                Task { @MainActor in
                    self?.transcribedText = partial
                }
            }
            isRecording = true
        } catch {
            isTranscribing = false
            isRecording = false
            presentError(error)
        }
    }

    func stopRecordingAndTranslate() async {
        guard isRecording else { return }

        do {
            let finalText = try await speechService.stopRecording()
            transcribedText = finalText
            isRecording = false
            isTranscribing = false
            await translateTranscribedText()
        } catch {
            isRecording = false
            isTranscribing = false
            presentError(error)
        }
    }

    func retranslateCurrentText() async {
        await translateTranscribedText()
    }

    private func translateTranscribedText() async {
        let source = transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else { return }

        isTranslating = true
        defer { isTranslating = false }

        do {
            translatedText = try await translationService.translate(text: source, to: selectedLanguageCode)
        } catch {
            presentError(error)
        }
    }

    var selectedLanguageName: String {
        availableLanguages.first(where: { $0.code == selectedLanguageCode })?.name ?? selectedLanguageCode.uppercased()
    }

    private func presentError(_ error: Error) {
        if let localized = error as? LocalizedError, let message = localized.errorDescription {
            errorMessage = message
        } else {
            errorMessage = error.localizedDescription
        }
        showError = true
    }
}
