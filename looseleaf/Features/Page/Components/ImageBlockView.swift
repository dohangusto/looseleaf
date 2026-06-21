import SwiftUI

/// An image embedded inline in the note, taking the available width.
struct ImageBlockView: View {
    let block: InputBlock

    var body: some View {
        Color.clear
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .overlay {
                Image(block.imageName ?? "page-content_1")
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
