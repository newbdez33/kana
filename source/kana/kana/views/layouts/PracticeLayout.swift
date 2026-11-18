import CoreGraphics

struct PracticeLayout {
    let question: CGRect
    let answers: CGRect

    init(bounds: CGRect, safeArea: CGRect, prefersColumns: Bool, divisions: [CGRect] = [],
         occlusions: [CGRect] = [], rightToLeft: Bool = false) {
        var available = safeArea
        // A side status bar reserves only part of the edge. Keep other safe-area insets.
        if occlusions.contains(where: { $0.minX <= bounds.minX && $0.maxX >= safeArea.minX
            && $0.maxX < bounds.midX && $0.intersects(bounds) }) {
            available.origin.x = bounds.minX
            available.size.width = safeArea.maxX - bounds.minX
        }
        if occlusions.contains(where: { $0.maxX >= bounds.maxX && $0.minX <= safeArea.maxX
            && $0.minX > bounds.midX && $0.intersects(bounds) }) {
            available.size.width = bounds.maxX - available.minX
        }
        let panes = PracticeLayout(bounds: available, prefersColumns: prefersColumns,
                                   divisions: divisions, rightToLeft: rightToLeft)
        question = panes.question
        answers = Self.horizontalFrame(in: panes.answers, avoiding: occlusions)
    }

    /// Keep a row at its current height and use the widest unobstructed interval.
    static func horizontalFrame(in bounds: CGRect, avoiding occlusions: [CGRect]) -> CGRect {
        var candidates = [bounds]
        for region in occlusions {
            candidates = candidates.flatMap { frame -> [CGRect] in
                let overlap = frame.intersection(region)
                guard !overlap.isNull, overlap.width > 0, overlap.height > 0 else { return [frame] }
                return [
                    CGRect(x: frame.minX, y: frame.minY, width: overlap.minX - frame.minX, height: frame.height),
                    CGRect(x: overlap.maxX, y: frame.minY, width: frame.maxX - overlap.maxX, height: frame.height)
                ]
            }
        }
        return candidates.max { $0.width < $1.width } ?? bounds
    }

    init(bounds: CGRect, prefersColumns: Bool, divisions: [CGRect] = [], rightToLeft: Bool = false) {
        var available = bounds
        for region in divisions {
            let vertical = region.height > region.width
            let crossesContent = vertical
                ? region.minY <= bounds.midY && region.maxY >= bounds.midY
                : region.minX <= bounds.midX && region.maxX >= bounds.midX
            guard crossesContent else { continue }

            let start = vertical ? bounds.minX : bounds.minY
            let end = vertical ? bounds.maxX : bounds.maxY
            let regionStart = vertical ? region.minX : region.minY
            let regionEnd = vertical ? region.maxX : region.maxY
            guard regionStart < end, regionEnd > start else { continue }

            let leadingLength = max(0, regionStart - start)
            let trailingLength = max(0, end - regionEnd)
            let leading = vertical
                ? CGRect(x: start, y: bounds.minY, width: leadingLength, height: bounds.height)
                : CGRect(x: bounds.minX, y: start, width: bounds.width, height: leadingLength)
            let trailing = vertical
                ? CGRect(x: end - trailingLength, y: bounds.minY, width: trailingLength, height: bounds.height)
                : CGRect(x: bounds.minX, y: end - trailingLength, width: bounds.width, height: trailingLength)

            // A narrow remnant beside the fold cannot hold the statistics or answer grid.
            let minimumLength: CGFloat = vertical ? 240 : 176
            if leadingLength >= minimumLength, trailingLength >= minimumLength {
                question = vertical && !rightToLeft ? trailing : leading
                answers = vertical && !rightToLeft ? leading : trailing
                return
            }
            available = leadingLength >= trailingLength ? leading : trailing
            break
        }

        if prefersColumns, available.width > available.height, available.width >= 480 {
            let leading = CGRect(x: available.minX, y: available.minY,
                                 width: available.width / 2, height: available.height)
            let trailing = leading.offsetBy(dx: leading.width, dy: 0)
            question = rightToLeft ? leading : trailing
            answers = rightToLeft ? trailing : leading
        } else {
            question = CGRect(x: available.minX, y: available.minY,
                              width: available.width, height: available.height * 0.6)
            answers = CGRect(x: available.minX, y: question.maxY,
                             width: available.width, height: available.maxY - question.maxY)
        }
    }
}
