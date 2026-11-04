import UIKit
import CoreText

final class QuestionGlyphLabel: UILabel {
    override func drawText(in rect: CGRect) {
        guard let text, !text.isEmpty, let font, let context = UIGraphicsGetCurrentContext() else { return }
        let coreFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): coreFont,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): textColor.cgColor,
        ]))
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        let advance = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
        let scale = min(1, min(rect.width / max(advance, 1), rect.height / max(font.lineHeight, 1)))
        // Center the visible glyphs; the font's line box has unequal empty space.
        context.saveGState()
        context.textMatrix = .identity
        context.translateBy(x: rect.midX - bounds.midX * scale, y: rect.midY + bounds.midY * scale)
        context.scaleBy(x: scale, y: -scale)
        context.textPosition = .zero
        CTLineDraw(line, context)
        context.restoreGState()
    }
}
