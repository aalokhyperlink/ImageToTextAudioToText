import SwiftUI

struct ContentView: View {
    @StateObject var viewModel: RunBuddyViewModel

    @State private var showImageSourceDialog = false
    @State private var showImagePicker = false
    @State private var imageSource: ImageSource = .photoLibrary

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemMint).opacity(0.25), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        Text("RunBuddy")
                            .font(.title2.bold())
                            .padding(.top, 8)

                        languagePickerSection
                        previewImage
                        actionButtons
                        extractedTextSection
                        transcribedTextSection
                        translatedTextSection
                    }
                    .padding(16)
                    .frame(maxWidth: 430)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color(.systemGreen).opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.7), lineWidth: 1)
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Select Image Source", isPresented: $showImageSourceDialog) {
                Button("Photo Library") {
                    imageSource = .photoLibrary
                    showImagePicker = true
                }
                Button("Camera") {
                    imageSource = .camera
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(source: imageSource.uiKitSourceType) { image in
                    Task {
                        await viewModel.handlePickedImage(image)
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .task {
                await viewModel.preparePermissions()
            }
            .onChange(of: viewModel.selectedLanguageCode) { _ in
                Task {
                    await viewModel.retranslateCurrentText()
                }
            }
        }
    }

    private var languagePickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Translation Language")
                .font(.subheadline.weight(.semibold))

            Picker("Translation Language", selection: $viewModel.selectedLanguageCode) {
                ForEach(viewModel.availableLanguages) { language in
                    Text(language.name).tag(language.code)
                }
            }
            .pickerStyle(.menu)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var previewImage: some View {
        Group {
            if let selectedImage = viewModel.selectedImage {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("OCR Selection", selection: $viewModel.useManualOCRSelection) {
                        Text("Manual Select").tag(true)
                        Text("All Detected Text").tag(false)
                    }
                    .pickerStyle(.segmented)

                    OCRSelectableImageView(
                        image: selectedImage,
                        blocks: viewModel.ocrBlocks,
                        selectedBlockIDs: viewModel.selectedOCRBlockIDs
                    ) { id in
                        viewModel.toggleOCRBlock(id)
                    }
                    .aspectRatio(imageAspectRatio(for: selectedImage), contentMode: .fit)
                    .frame(maxWidth: .infinity)

                    if !viewModel.ocrBlocks.isEmpty {
                        HStack(spacing: 10) {
                            Button("Select All") {
                                viewModel.selectAllOCRBlocks()
                            }
                            .buttonStyle(.bordered)

                            Button("Copy Selected Text") {
                                viewModel.copySelectedOCRText()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.indigo)

                            Button("Clear Selection") {
                                viewModel.clearSelectedOCRBlocks()
                            }
                            .buttonStyle(.bordered)
                        }

                        Text("Tap highlighted boxes to select specific text.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func imageAspectRatio(for image: UIImage) -> CGFloat {
        let width = max(image.size.width, 1)
        let height = max(image.size.height, 1)
        return width / height
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button("Upload Image") {
                showImageSourceDialog = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .frame(maxWidth: .infinity)

            Button("Start Recording") {
                Task {
                    await viewModel.startRecording()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(viewModel.isRecording)
            .frame(maxWidth: .infinity)

            Button("Stop Recording") {
                Task {
                    await viewModel.stopRecordingAndTranslate()
                }
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .disabled(!viewModel.isRecording)
            .frame(maxWidth: .infinity)

            if viewModel.isRecording {
                Text("Recording...")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var extractedTextSection: some View {
        let manualSelectedText = viewModel.selectedOCRText.trimmingCharacters(in: .whitespacesAndNewlines)
        let content = viewModel.useManualOCRSelection
            ? (manualSelectedText.isEmpty ? "Select text boxes on the image to show text here." : manualSelectedText)
            : viewModel.extractedText

        return TextSectionCard(
            title: "Extracted Text from Image",
            content: content,
            isLoading: viewModel.isExtractingText,
            minHeight: 220
        )
    }

    private var transcribedTextSection: some View {
        TextSectionCard(
            title: "Transcribed Text",
            content: viewModel.transcribedText,
            isLoading: viewModel.isTranscribing,
            minHeight: 140
        )
    }

    private var translatedTextSection: some View {
        TextSectionCard(
            title: "Translated Text (\(viewModel.selectedLanguageName))",
            content: viewModel.translatedText,
            isLoading: viewModel.isTranslating,
            minHeight: 140
        )
    }
}

#Preview {
    ContentView(viewModel: RunBuddyViewModel())
}
