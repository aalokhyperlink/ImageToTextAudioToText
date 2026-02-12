import SwiftUI

struct OCRSelectableImageView: View {
    let image: UIImage
    let blocks: [OCRTextBlock]
    let selectedBlockIDs: Set<UUID>
    let onTapBlock: (UUID) -> Void

    var body: some View {
        GeometryReader { proxy in
            let imageRect = aspectFitRect(for: image.size, in: proxy.size)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.04))

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageRect.width, height: imageRect.height)
                    .position(x: imageRect.midX, y: imageRect.midY)

                ForEach(blocks) { block in
                    let rect = rectForVisionBoundingBox(block.boundingBox, in: imageRect)
                    let isSelected = selectedBlockIDs.contains(block.id)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(isSelected ? Color.yellow.opacity(0.28) : Color.blue.opacity(0.16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(isSelected ? Color.orange : Color.blue, lineWidth: isSelected ? 2 : 1)
                        )
                        .frame(width: max(rect.width, 14), height: max(rect.height, 14))
                        .position(x: rect.midX, y: rect.midY)
                        .onTapGesture {
                            onTapBlock(block.id)
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func rectForVisionBoundingBox(_ boundingBox: CGRect, in imageRect: CGRect) -> CGRect {
        let x = imageRect.minX + (boundingBox.minX * imageRect.width)
        let y = imageRect.minY + ((1.0 - boundingBox.maxY) * imageRect.height)
        let width = boundingBox.width * imageRect.width
        let height = boundingBox.height * imageRect.height
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func aspectFitRect(for imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, containerSize.width > 0, containerSize.height > 0 else {
            return .zero
        }

        let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        let x = (containerSize.width - width) / 2
        let y = (containerSize.height - height) / 2

        return CGRect(x: x, y: y, width: width, height: height)
    }
}
