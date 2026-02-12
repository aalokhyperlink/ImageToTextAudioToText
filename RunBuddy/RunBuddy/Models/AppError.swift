import Foundation

enum AppError: LocalizedError {
    case invalidImage
    case noTextFound
    case ocrFailed
    case speechRecognizerUnavailable
    case speechPermissionDenied
    case microphonePermissionDenied
    case recordingNotStarted
    case translationFailed
    case noSelectedText

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The selected image is invalid."
        case .noTextFound:
            return "No text could be detected."
        case .ocrFailed:
            return "Text extraction failed. Please try another image."
        case .speechRecognizerUnavailable:
            return "Speech recognition is not available on this device."
        case .speechPermissionDenied:
            return "Speech recognition permission was denied."
        case .microphonePermissionDenied:
            return "Microphone permission was denied."
        case .recordingNotStarted:
            return "Recording session is not active."
        case .translationFailed:
            return "Translation failed."
        case .noSelectedText:
            return "Select text from the image overlay before copying."
        }
    }
}
