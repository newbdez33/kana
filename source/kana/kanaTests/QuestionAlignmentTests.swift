import XCTest
import UIKit
import CoreImage
@testable import kana

@MainActor
final class QuestionAlignmentTests: XCTestCase {
    func testVisibleGlyphsAreCenteredForKanaAndRomaji() throws {
        let label = PracticeView().questionLabel
        label.removeFromSuperview()
        label.backgroundColor = .white
        let context = CIContext(options: [.useSoftwareRenderer: true])
        for side in [160, 100] {
            label.frame = CGRect(x: 0, y: 0, width: side, height: side)
            for text in ["mo", "shi", "a", "ふ", "あ", "ニ", "く", "を"] {
                label.text = text
                label.setNeedsDisplay()
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                format.preferredRange = .standard
                let image = UIGraphicsImageRenderer(size: label.bounds.size, format: format).image {
                    label.layer.render(in: $0.cgContext)
                }
                let cgImage = try XCTUnwrap(image.cgImage)
                var pixels = [UInt8](repeating: 0, count: side * side * 4)
                pixels.withUnsafeMutableBytes {
                    context.render(CIImage(cgImage: cgImage), toBitmap: $0.baseAddress!, rowBytes: side * 4,
                                   bounds: label.bounds, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
                }
                var left = side, top = side, right = -1, bottom = -1
                for y in 0..<side {
                    for x in 0..<side {
                        let index = (y * side + x) * 4
                        if pixels[index] < 51 && pixels[index + 1] < 51 && pixels[index + 2] < 51 && pixels[index + 3] > 192 {
                            left = min(left, x); right = max(right, x)
                            top = min(top, y); bottom = max(bottom, y)
                        }
                    }
                }
                XCTAssertGreaterThanOrEqual(right, left, "\(text) must remain visible")
                XCTAssertEqual(Double(top + bottom + 1) / 2, Double(side) / 2, accuracy: 1.5, "\(text) vertical center")
                XCTAssertEqual(Double(left + right + 1) / 2, Double(side) / 2, accuracy: 1.5, "\(text) horizontal center")
                XCTAssertGreaterThan(top, 0, "\(text) top edge")
                XCTAssertLessThan(bottom, side - 1, "\(text) bottom edge")
            }
        }
    }
}
