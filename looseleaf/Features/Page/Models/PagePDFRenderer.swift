import UIKit

/// Renders a page (title + blocks) into a simple multi-page PDF file.
enum PagePDFRenderer {
    static func makePDF(title: String, blocks: [InputBlock]) -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let margin: CGFloat = 40
        let contentWidth = pageRect.width - margin * 2
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let fileName = sanitized(title.isEmpty ? "Note" : title) + ".pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try renderer.writePDF(to: url) { ctx in
                ctx.beginPage()
                var y = margin

                func reserve(_ height: CGFloat) {
                    if y + height > pageRect.height - margin {
                        ctx.beginPage()
                        y = margin
                    }
                }

                func draw(_ string: NSAttributedString, spacing: CGFloat) {
                    let height = string.boundingRect(
                        with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                        options: .usesLineFragmentOrigin, context: nil
                    ).height
                    reserve(height)
                    string.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: height))
                    y += height + spacing
                }

                // Title
                draw(NSAttributedString(string: title,
                                        attributes: [.font: UIFont.boldSystemFont(ofSize: 26)]),
                     spacing: 18)

                for block in blocks {
                    if block.type == .image, let name = block.imageName, let image = UIImage(named: name) {
                        let ratio = image.size.height / max(image.size.width, 1)
                        let height = min(contentWidth * ratio, 300)
                        reserve(height)
                        image.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: height))
                        y += height + 14
                    } else {
                        draw(attributed(for: block), spacing: 12)
                    }
                }
            }
            return url
        } catch {
            return nil
        }
    }

    private static func attributed(for block: InputBlock) -> NSAttributedString {
        let body = UIFont.systemFont(ofSize: 13)
        let bold = UIFont.boldSystemFont(ofSize: 13)
        let italic = UIFont.italicSystemFont(ofSize: 12)

        switch block.type {
        case .default, .text:
            return NSAttributedString(string: block.text, attributes: [.font: body])
        case .vocabulary:
            let s = NSMutableAttributedString(string: "\(block.text) ", attributes: [.font: bold])
            s.append(NSAttributedString(string: block.secondaryText, attributes: [.font: italic]))
            return s
        case .quote:
            let s = NSMutableAttributedString(string: "“\(block.text)”\n", attributes: [.font: bold])
            if !block.secondaryText.isEmpty {
                s.append(NSAttributedString(string: block.secondaryText, attributes: [.font: italic]))
            }
            return s
        case .voiceNote:
            let s = NSMutableAttributedString(string: "🎙 \(block.text)\n", attributes: [.font: bold])
            s.append(NSAttributedString(string: block.transcript, attributes: [.font: italic]))
            return s
        case .expenses:
            let lines = block.expenses
                .map { "• \($0.category): \(RupiahFormatter.string($0.amount))" }
                .joined(separator: "\n")
            let total = "Total: \(RupiahFormatter.string(block.expensesTotal))"
            return NSAttributedString(string: "\(lines)\n\(total)", attributes: [.font: body])
        case .image:
            return NSAttributedString(string: "[image]", attributes: [.font: italic])
        }
    }

    private static func sanitized(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(.whitespaces)
        return String(name.unicodeScalars.filter { allowed.contains($0) })
            .trimmingCharacters(in: .whitespaces)
    }
}
