import Foundation
import CoreGraphics

// These are review fixtures. The app reads actual safe areas and reserved regions from UIKit.
@main
struct ExportDuoLayouts {
    static func main() throws {
        let cases: [(String, String, CGSize, [CGFloat], Bool, [CGRect])] = [
            ("closed", "Closed", CGSize(width: 466, height: 678), [0, 0, 0, 84], false, []),
            ("open", "Open flat", CGSize(width: 951, height: 669), [0, 0, 0, 84], true,
             [CGRect(x: 475.5, y: 0, width: 0, height: 669)]),
            ("book", "Book", CGSize(width: 951, height: 669), [0, 0, 0, 84], true,
             [CGRect(x: 459, y: 0, width: 33, height: 669)]),
            ("tabletop", "Tabletop", CGSize(width: 669, height: 951), [84, 0, 95, 0], false,
             [CGRect(x: 0, y: 375, width: 669, height: 34)]),
            ("split-left", "Split View · left", CGSize(width: 475.5, height: 669), [0, 84, 0, 0], false,
             [CGRect(x: 375, y: 0, width: 33, height: 669)]),
            ("split-right", "Split View · right", CGSize(width: 475.5, height: 669), [0, 0, 0, 84], false,
             [CGRect(x: -16.5, y: 0, width: 33, height: 669)])
        ]
        let records: [[String: Any]] = cases.map { id, name, size, insets, columns, divisions in
            let top = insets[0], left = insets[1], bottom = insets[2], right = insets[3]
            let bounds = CGRect(x: 0, y: 0, width: size.width - left - right,
                                height: size.height - top - bottom)
            let layout = PracticeLayout(bounds: bounds, prefersColumns: columns, divisions: divisions)
            func coordinates(_ rect: CGRect) -> [CGFloat] {
                [rect.minX + left, rect.minY + top, rect.width, rect.height]
            }
            return ["id": id, "name": name, "size": [size.width, size.height], "insets": insets,
                    "question": coordinates(layout.question), "answers": coordinates(layout.answers),
                    "divisions": divisions.map(coordinates)]
        }
        let data = try JSONSerialization.data(withJSONObject: records, options: [.prettyPrinted, .sortedKeys])
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }
}
