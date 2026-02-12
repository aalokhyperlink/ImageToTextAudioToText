import AVFoundation
import Foundation
import Speech

protocol SpeechTranscribing: AnyObject {
    func requestPermissions() async throws
    func startRecording(onPartialResult: @escaping (String) -> Void) throws
    func stopRecording() async throws -> String
}

final class SpeechRecognitionService: NSObject, SpeechTranscribing {
    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var currentTranscription = ""

    func requestPermissions() async throws {
        let speechStatus = await requestSpeechAuthorization()
        guard speechStatus == .authorized else {
            throw AppError.speechPermissionDenied
        }

        let micAllowed = await requestMicrophoneAuthorization()
        guard micAllowed else {
            throw AppError.microphonePermissionDenied
        }
    }

    func startRecording(onPartialResult: @escaping (String) -> Void) throws {
        guard let recognizer, recognizer.isAvailable else {
            throw AppError.speechRecognizerUnavailable
        }

        recognitionTask?.cancel()
        recognitionTask = nil

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        recognitionRequest = request
        currentTranscription = ""

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let text = result.bestTranscription.formattedString
                self.currentTranscription = text
                onPartialResult(text)
            }

            if error != nil {
                self.audioEngine.stop()
                self.recognitionRequest?.endAudio()
                inputNode.removeTap(onBus: 0)
            }
        }
    }

    func stopRecording() async throws -> String {
        guard audioEngine.isRunning else {
            throw AppError.recordingNotStarted
        }

        audioEngine.stop()
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        let session = AVAudioSession.sharedInstance()
        try session.setActive(false, options: .notifyOthersOnDeactivation)

        return currentTranscription.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    private func requestMicrophoneAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
    }
}
