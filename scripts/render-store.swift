import AppKit

// Usage: swift scripts/render-store.swift store/metadata.json captures output [android]
struct StoreCopy: Decodable {
    let appName: String
    let shots: [[String]]
}

struct RenderedScreenshot: Encodable {
    let locale: String
    let device: String
    let order: Int
    let file: String
    let source: String
    let width: Int
    let height: Int
    let titleFontSize: Double
    let captionFontSize: Double
}

enum RenderError: Error {
    case invalidArguments, invalidCopy(String), missingImage(String)
    case invalidImageSize(String), textOverflow(String)
}

guard (4...5).contains(CommandLine.arguments.count) else { throw RenderError.invalidArguments }
let android = CommandLine.arguments.count == 5 && CommandLine.arguments[4] == "android"
guard CommandLine.arguments.count == 4 || android else { throw RenderError.invalidArguments }
let copyURL = URL(fileURLWithPath: CommandLine.arguments[1])
let sourceRoot = URL(fileURLWithPath: CommandLine.arguments[2])
let outputRoot = URL(fileURLWithPath: CommandLine.arguments[3])
let copyData = try Data(contentsOf: copyURL)
let copies = try JSONDecoder().decode([String: StoreCopy].self, from: copyData)
let locales = ["en-US", "ja", "zh-Hans", "zh-Hant", "ko"]

func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: 1)
}

let ink = color(0x231e1c)
let paper = color(0xfffaf3)
let backgrounds = [color(0xf5e1da), color(0xeee7d9), ink, color(0xc93332)]

func font(_ locale: String, size: CGFloat, bold: Bool) -> NSFont {
    let name: String
    switch locale {
    case "ja": name = bold ? "HiraginoSans-W6" : "HiraginoSans-W3"
    case "zh-Hans": name = bold ? "PingFangSC-Semibold" : "PingFangSC-Regular"
    case "zh-Hant": name = bold ? "PingFangTC-Semibold" : "PingFangTC-Regular"
    case "ko": name = bold ? "AppleSDGothicNeo-SemiBold" : "AppleSDGothicNeo-Regular"
    default: name = bold ? "HelveticaNeue-Bold" : "HelveticaNeue"
    }
    return NSFont(name: name, size: size)
        ?? NSFont.systemFont(ofSize: size, weight: bold ? .bold : .regular)
}

@discardableResult
func text(_ value: String, locale: String, rect: CGRect, size: CGFloat,
          minimum: CGFloat, bold: Bool, color: NSColor) throws -> CGFloat {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byWordWrapping
    var fitted = size
    while fitted >= minimum {
        paragraph.lineSpacing = fitted * 0.08
        let attributed = NSAttributedString(string: value, attributes: [
            .font: font(locale, size: fitted, bold: bold),
            .foregroundColor: color,
            .paragraphStyle: paragraph,
        ])
        let bounds = attributed.boundingRect(
            with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        if ceil(bounds.height) <= rect.height && ceil(bounds.width) <= rect.width {
            attributed.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading])
            return fitted
        }
        fitted -= 2
    }
    throw RenderError.textOverflow("\(locale): \(value)")
}

func render(locale: String, copy: StoreCopy, device: String,
            order: Int, shot: [String]) throws -> RenderedScreenshot {
    guard shot.count == 4 else { throw RenderError.invalidCopy(locale) }
    let ipad = device == "ipad"
    let width = android ? 1080 : (ipad ? 2064 : 1320)
    let height = android ? 1920 : (ipad ? 2752 : 2868)
    let language = locale == "en-US" ? "en" : locale
    let source = "\(language)/\(device)/\(shot[3])"
    let sourceURL = sourceRoot.appendingPathComponent(source)
    guard let image = NSImage(contentsOf: sourceURL),
          let bitmap = NSBitmapImageRep(data: try Data(contentsOf: sourceURL)) else {
        throw RenderError.missingImage(source)
    }
    guard bitmap.pixelsWide == width, bitmap.pixelsHigh == height else {
        throw RenderError.invalidImageSize(source)
    }
    let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8,
        bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )!
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    context.translateBy(x: 0, y: CGFloat(height))
    context.scaleBy(x: 1, y: -1)
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
    var titleSize: CGFloat = 0
    var captionSize: CGFloat = 0
    if android {
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height),
                   from: .zero, operation: .copy, fraction: 1, respectFlipped: true, hints: nil)
    } else {
        backgrounds[order].setFill()
        NSBezierPath(rect: CGRect(x: 0, y: 0, width: width, height: height)).fill()
        let foreground = order < 2 ? ink : paper
        let margin: CGFloat = ipad ? 156 : 104
        let textWidth = CGFloat(width) - 2 * margin
        try text(copy.appName, locale: locale,
                 rect: CGRect(x: margin, y: ipad ? 70 : 76, width: textWidth, height: 88),
                 size: ipad ? 48 : 38, minimum: 32, bold: true,
                 color: foreground.withAlphaComponent(0.75))
        titleSize = try text(shot[0], locale: locale,
                                 rect: CGRect(x: margin, y: ipad ? 202 : 192, width: textWidth,
                                              height: ipad ? 302 : 272),
                                 size: ipad ? 124 : 100, minimum: ipad ? 94 : 76,
                                 bold: true, color: foreground)
        captionSize = try text(shot[1], locale: locale,
                                   rect: CGRect(x: margin, y: ipad ? 518 : 490, width: textWidth,
                                                height: ipad ? 160 : 148),
                                   size: ipad ? 61 : 49, minimum: ipad ? 48 : 39,
                                   bold: false, color: foreground.withAlphaComponent(0.88))
        let imageHeight: CGFloat = ipad ? 1940 : 2098
        let imageWidth = imageHeight * CGFloat(width) / CGFloat(height)
        let imageRect = CGRect(x: (CGFloat(width) - imageWidth) / 2,
                               y: CGFloat(height) - imageHeight - 74,
                               width: imageWidth, height: imageHeight)
        ink.setFill()
        NSBezierPath(roundedRect: imageRect.insetBy(dx: -14, dy: -14),
                     xRadius: ipad ? 40 : 56, yRadius: ipad ? 40 : 56).fill()
        context.saveGState()
        NSBezierPath(roundedRect: imageRect, xRadius: ipad ? 26 : 42,
                     yRadius: ipad ? 26 : 42).addClip()
        image.draw(in: imageRect, from: .zero, operation: .sourceOver, fraction: 1,
                   respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
        context.restoreGState()
    }

    let file = "screenshots/\(device)/\(locale)/\(String(format: "%02d", order + 1))-\(shot[2]).png"
    let destination = outputRoot.appendingPathComponent(file)
    try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(),
                                            withIntermediateDirectories: true)
    let result = NSBitmapImageRep(cgImage: context.makeImage()!)
    try result.representation(using: .png, properties: [:])!.write(to: destination)
    return RenderedScreenshot(locale: locale, device: device, order: order, file: file,
                              source: source, width: width, height: height,
                              titleFontSize: Double(titleSize), captionFontSize: Double(captionSize))
}

var outputs: [RenderedScreenshot] = []
for device in android ? ["phone", "tablet"] : ["iphone", "ipad"] {
    for locale in locales {
        guard let copy = copies[locale], copy.shots.count == 4 else {
            throw RenderError.invalidCopy(locale)
        }
        for (order, shot) in copy.shots.enumerated() {
            outputs.append(try autoreleasepool {
                try render(locale: locale, copy: copy, device: device, order: order, shot: shot)
            })
        }
        print("Rendered \(device) \(locale): \(copy.shots.count) screenshots")
    }
}
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
try encoder.encode(outputs).write(to: outputRoot.appendingPathComponent("layout.json"))
try copyData.write(to: outputRoot.appendingPathComponent("metadata.json"))
let storeRoot = android ? copyURL.deletingLastPathComponent().deletingLastPathComponent()
    : copyURL.deletingLastPathComponent()
let previewURL = storeRoot.appendingPathComponent("preview.html")
try Data(contentsOf: previewURL).write(to: outputRoot.appendingPathComponent("index.html"))

if android {
    let uploadRoot = outputRoot.appendingPathComponent("upload")
    try FileManager.default.createDirectory(at: uploadRoot, withIntermediateDirectories: true)
    for output in outputs {
        let name = "\(output.device)-\(output.locale)-\(URL(fileURLWithPath: output.file).lastPathComponent)"
        try Data(contentsOf: outputRoot.appendingPathComponent(output.file))
            .write(to: uploadRoot.appendingPathComponent(name))
    }
    let iconURL = storeRoot.deletingLastPathComponent()
        .appendingPathComponent("source/kana/kana/Assets.xcassets/AppIcon.appiconset/Icon-1024.png")
    guard let icon = NSImage(contentsOf: iconURL) else { throw RenderError.missingImage(iconURL.path) }
    func bitmap(width: Int, height: Int, alpha: Bool = false, draw: () throws -> Void) throws -> Data {
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: (alpha ? CGImageAlphaInfo.premultipliedLast : .noneSkipLast).rawValue)!
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
        try draw()
        return NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])!
    }
    try bitmap(width: 512, height: 512, alpha: true) {
        icon.draw(in: CGRect(x: 0, y: 0, width: 512, height: 512), from: .zero,
                  operation: .copy, fraction: 1, respectFlipped: true,
                  hints: [.interpolation: NSImageInterpolation.high])
    }.write(to: outputRoot.appendingPathComponent("icon.png"))
    for locale in locales {
        let copy = copies[locale]!
        try bitmap(width: 1024, height: 500) {
            backgrounds[0].setFill()
            NSBezierPath(rect: CGRect(x: 0, y: 0, width: 1024, height: 500)).fill()
            try text("KANA · 五十音", locale: "ja", rect: CGRect(x: 72, y: 68, width: 570, height: 52),
                     size: 27, minimum: 27, bold: true, color: ink.withAlphaComponent(0.65))
            try text(copy.shots[0][0], locale: locale, rect: CGRect(x: 72, y: 156, width: 560, height: 190),
                     size: 60, minimum: 44, bold: true, color: ink)
            for (index, glyph) in ["あ", "ア", "a"].enumerated() {
                let rect = CGRect(x: 708 + index * 12, y: 64 + index * 120, width: 184, height: 106)
                (index == 1 ? color(0xc93332) : paper).setFill()
                NSBezierPath(roundedRect: rect, xRadius: 20, yRadius: 20).fill()
                try text(glyph, locale: "ja", rect: rect.insetBy(dx: 58, dy: 10),
                         size: 64, minimum: 56, bold: true, color: index == 1 ? paper : ink)
            }
        }.write(to: outputRoot.appendingPathComponent("feature-\(locale).png"))
    }
}
