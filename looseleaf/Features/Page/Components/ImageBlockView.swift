import SwiftUI

/// An image embedded inline in the note, taking the available width.
struct ImageBlockView: View {
    let block: InputBlock

    private var imageContent: Image {
        if let data = block.imageData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return Image(block.imageName ?? "page-content_1")
    }

    var body: some View {
        Color.clear
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .overlay {
                imageContent
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    ImageBlockView(block: InputBlock(type: .image, imageName: "page-content_1"))
        .padding()
}
