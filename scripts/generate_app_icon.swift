import AppKit
import CoreGraphics
import Foundation

func createCGContext(width: Int, height: Int) -> CGContext {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    let context = CGContext(data: nil,
                            width: width,
                            height: height,
                            bitsPerComponent: 8,
                            bytesPerRow: width * 4,
                            space: colorSpace,
                            bitmapInfo: bitmapInfo)!
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.interpolationQuality = .high
    return context
}

func hexColor(_ hex: UInt32, alpha: CGFloat = 1.0) -> NSColor {
    let r = CGFloat((hex >> 16) & 0xFF) / 255.0
    let g = CGFloat((hex >> 8) & 0xFF) / 255.0
    let b = CGFloat(hex & 0xFF) / 255.0
    return NSColor(red: r, green: g, blue: b, alpha: alpha)
}

func renderVerseIcon1024() -> CGImage {
    let ctx = createCGContext(width: 1024, height: 1024)
    let squircleRect = CGRect(x: 104, y: 104, width: 816, height: 816)
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    let path = CGPath(roundedRect: squircleRect, cornerWidth: 185, cornerHeight: 185, transform: nil)

    // 1. Ambient Drop Shadows (Standard macOS icon multi-layer shadow)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -36), blur: 50, color: NSColor.black.withAlphaComponent(0.42).cgColor)
    ctx.addPath(path)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 18, color: NSColor.black.withAlphaComponent(0.24).cgColor)
    ctx.addPath(path)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // 2. Base Surface Fill
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()

    // Vertical dark graphite gradient
    let bgColors = [hexColor(0x191A28).cgColor, hexColor(0x0C0D15).cgColor] as CFArray
    let bgGrad = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(bgGrad,
                           start: CGPoint(x: squircleRect.midX, y: squircleRect.maxY),
                           end: CGPoint(x: squircleRect.midX, y: squircleRect.minY),
                           options: [])

    // Ambient radial lighting (deep violet bloom)
    let glowColors = [hexColor(0x7C3AED, alpha: 0.18).cgColor, hexColor(0x7C3AED, alpha: 0.0).cgColor] as CFArray
    let glowGrad = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0])!
    ctx.drawRadialGradient(glowGrad,
                           startCenter: CGPoint(x: squircleRect.midX, y: squircleRect.midY - 20),
                           startRadius: 0,
                           endCenter: CGPoint(x: squircleRect.midX, y: squircleRect.midY - 20),
                           endRadius: squircleRect.width * 0.58,
                           options: [])

    // Inner chamfer / rim highlight
    ctx.setLineWidth(1.5)
    let rimColors = [
        NSColor.white.withAlphaComponent(0.24).cgColor,
        NSColor.white.withAlphaComponent(0.07).cgColor,
        NSColor.white.withAlphaComponent(0.02).cgColor
    ] as CFArray
    let rimGrad = CGGradient(colorsSpace: colorSpace, colors: rimColors, locations: [0.0, 0.45, 1.0])!
    ctx.saveGState()
    ctx.addPath(path)
    ctx.replacePathWithStrokedPath()
    ctx.clip()
    ctx.drawLinearGradient(rimGrad,
                           start: CGPoint(x: squircleRect.midX, y: squircleRect.maxY),
                           end: CGPoint(x: squircleRect.midX, y: squircleRect.minY),
                           options: [])
    ctx.restoreGState()

    // 3. Concentric Acoustic Ripples (Echo)
    let rippleCenter = CGPoint(x: squircleRect.midX, y: squircleRect.midY - 15)
    let rippleRadii: [CGFloat] = [170, 240, 310]
    for (i, r) in rippleRadii.enumerated() {
        let alpha = 0.07 - CGFloat(i) * 0.02
        ctx.saveGState()
        ctx.setLineWidth(1.2)
        ctx.setStrokeColor(hexColor(0x818CF8, alpha: alpha).cgColor)
        ctx.strokeEllipse(in: CGRect(x: rippleCenter.x - r, y: rippleCenter.y - r, width: r * 2, height: r * 2))
        ctx.restoreGState()
    }

    // 4. MacBook Display Notch at top
    let notchW: CGFloat = 264
    let notchH: CGFloat = 66
    let notchRect = CGRect(x: squircleRect.midX - notchW / 2, y: squircleRect.maxY - notchH, width: notchW, height: notchH + 15)
    let notchPath = CGMutablePath()
    notchPath.move(to: CGPoint(x: notchRect.minX - 18, y: notchRect.maxY))
    notchPath.addQuadCurve(to: CGPoint(x: notchRect.minX + 16, y: notchRect.minY + 22),
                           control: CGPoint(x: notchRect.minX + 2, y: notchRect.maxY - 8))
    notchPath.addArc(tangent1End: CGPoint(x: notchRect.minX + 16, y: notchRect.minY),
                     tangent2End: CGPoint(x: notchRect.minX + 40, y: notchRect.minY),
                     radius: 18)
    notchPath.addLine(to: CGPoint(x: notchRect.maxX - 40, y: notchRect.minY))
    notchPath.addArc(tangent1End: CGPoint(x: notchRect.maxX - 16, y: notchRect.minY),
                     tangent2End: CGPoint(x: notchRect.maxX - 16, y: notchRect.minY + 22),
                     radius: 18)
    notchPath.addQuadCurve(to: CGPoint(x: notchRect.maxX + 18, y: notchRect.maxY),
                           control: CGPoint(x: notchRect.maxX - 2, y: notchRect.maxY - 8))
    notchPath.closeSubpath()

    // Notch shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 16, color: NSColor.black.withAlphaComponent(0.7).cgColor)
    ctx.addPath(notchPath)
    ctx.setFillColor(hexColor(0x060709).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Notch stroke
    ctx.saveGState()
    ctx.addPath(notchPath)
    ctx.setLineWidth(1.2)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.12).cgColor)
    ctx.strokePath()
    ctx.restoreGState()

    // Camera lens + status LED
    let camX = squircleRect.midX
    let camY = squircleRect.maxY - notchH / 2 + 3
    ctx.saveGState()
    ctx.setFillColor(hexColor(0x13141F).cgColor)
    ctx.fillEllipse(in: CGRect(x: camX - 8, y: camY - 8, width: 16, height: 16))
    ctx.setFillColor(hexColor(0x052E16, alpha: 0.9).cgColor)
    ctx.fillEllipse(in: CGRect(x: camX - 4, y: camY - 4, width: 8, height: 8))
    ctx.setFillColor(hexColor(0x10B981, alpha: 0.9).cgColor)
    ctx.fillEllipse(in: CGRect(x: camX + 24, y: camY - 3, width: 6, height: 6))
    ctx.restoreGState()

    // 5. Dual-Line Synced Lyric Subtitle
    // Line 1: Active singing lyric line
    let beam1W: CGFloat = 164
    let beam1H: CGFloat = 8
    let beam1Y = notchRect.minY - 24
    let b1Rect = CGRect(x: squircleRect.midX - beam1W / 2, y: beam1Y - beam1H / 2, width: beam1W, height: beam1H)
    let b1Path = CGPath(roundedRect: b1Rect, cornerWidth: beam1H / 2, cornerHeight: beam1H / 2, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -2), blur: 14, color: hexColor(0x38BDF8, alpha: 0.55).cgColor)
    ctx.addPath(b1Path)
    ctx.clip()
    let beamGradColors = [hexColor(0x38BDF8).cgColor, hexColor(0x818CF8).cgColor] as CFArray
    let beamGrad = CGGradient(colorsSpace: colorSpace, colors: beamGradColors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(beamGrad, start: CGPoint(x: b1Rect.minX, y: beam1Y), end: CGPoint(x: b1Rect.maxX, y: beam1Y), options: [])
    ctx.restoreGState()

    // Line 2: Upcoming lyric preview line
    let beam2W: CGFloat = 104
    let beam2H: CGFloat = 5
    let beam2Y = beam1Y - 14
    let b2Rect = CGRect(x: squircleRect.midX - beam2W / 2, y: beam2Y - beam2H / 2, width: beam2W, height: beam2H)
    let b2Path = CGPath(roundedRect: b2Rect, cornerWidth: beam2H / 2, cornerHeight: beam2H / 2, transform: nil)
    ctx.saveGState()
    ctx.addPath(b2Path)
    ctx.setFillColor(NSColor.white.withAlphaComponent(0.20).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // 6. Central Motif: Bold, Clean & Subtle Acoustic "V"
    let pLeft = CGPoint(x: squircleRect.midX - 190, y: squircleRect.midY + 105)
    let pVertex = CGPoint(x: squircleRect.midX, y: squircleRect.midY - 160)
    let pRight = CGPoint(x: squircleRect.midX + 190, y: squircleRect.midY + 105)
    let strokeW: CGFloat = 58

    let vPath = CGMutablePath()
    vPath.move(to: pLeft)
    vPath.addArc(tangent1End: pVertex, tangent2End: pRight, radius: 52)
    vPath.addLine(to: pRight)

    let strokedV = vPath.copy(strokingWithWidth: strokeW, lineCap: .round, lineJoin: .round, miterLimit: 10)

    // Soft radiant ambient glow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 50, color: hexColor(0x8B5CF6, alpha: 0.55).cgColor)
    ctx.addPath(strokedV)
    ctx.setFillColor(hexColor(0x8B5CF6, alpha: 0.30).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Radiant gradient fill
    ctx.saveGState()
    ctx.addPath(strokedV)
    ctx.clip()

    let vColors = [
        hexColor(0x38BDF8).cgColor, // Luminous Cyan
        hexColor(0x6366F1).cgColor, // Indigo
        hexColor(0xA855F7).cgColor, // Electric Violet
        hexColor(0xEC4899).cgColor, // Rose
        hexColor(0xFB7185).cgColor  // Coral
    ] as CFArray
    let vGrad = CGGradient(colorsSpace: colorSpace, colors: vColors, locations: [0.0, 0.28, 0.55, 0.82, 1.0])!
    let vBounds = strokedV.boundingBox
    ctx.drawLinearGradient(vGrad,
                           start: CGPoint(x: vBounds.minX, y: vBounds.maxY),
                           end: CGPoint(x: vBounds.maxX, y: vBounds.minY),
                           options: [])

    // Specular sheen along top surface
    let sheenColors = [
        NSColor.white.withAlphaComponent(0.35).cgColor,
        NSColor.white.withAlphaComponent(0.0).cgColor
    ] as CFArray
    let sheenGrad = CGGradient(colorsSpace: colorSpace, colors: sheenColors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(sheenGrad,
                           start: CGPoint(x: vBounds.midX, y: vBounds.maxY),
                           end: CGPoint(x: vBounds.midX, y: vBounds.midY - 20),
                           options: [])
    ctx.restoreGState()

    // Inner rim stroke
    ctx.saveGState()
    ctx.addPath(strokedV)
    ctx.setLineWidth(1.8)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.24).cgColor)
    ctx.strokePath()
    ctx.restoreGState()

    ctx.restoreGState() // pop squircle clip

    return ctx.makeImage()!
}

func resizeAndSave(image: CGImage, width: Int, height: Int, destinationURL: URL) -> Data? {
    let ctx = createCGContext(width: width, height: height)
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    guard let scaledImage = ctx.makeImage() else { return nil }
    let rep = NSBitmapImageRep(cgImage: scaledImage)
    guard let pngData = rep.representation(using: .png, properties: [:]) else { return nil }
    try? pngData.write(to: destinationURL)
    return pngData
}

// Generate the master image
print("Rendering 1024x1024 master icon...")
let masterImage = renderVerseIcon1024()

let rootDir = FileManager.default.currentDirectoryPath
let resourcesDir = URL(fileURLWithPath: "\(rootDir)/Resources")
let iconsetDir = resourcesDir.appendingPathComponent("AppIcon.iconset")

try? FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

// Save 1024 master PNG
let masterURL = resourcesDir.appendingPathComponent("AppIcon-1024.png")
let masterRep = NSBitmapImageRep(cgImage: masterImage)
if let masterData = masterRep.representation(using: .png, properties: [:]) {
    try? masterData.write(to: masterURL)
    print("Saved \(masterURL.path)")
}

// Standard macOS Icon Resolutions and ICNS tags
let iconConfigs: [(name: String, size: Int, tag: String)] = [
    ("icon_16x16.png", 16, "icp4"),
    ("icon_16x16@2x.png", 32, "ic11"),
    ("icon_32x32.png", 32, "icp5"),
    ("icon_32x32@2x.png", 64, "ic12"),
    ("icon_128x128.png", 128, "ic07"),
    ("icon_128x128@2x.png", 256, "ic13"),
    ("icon_256x256.png", 256, "ic08"),
    ("icon_256x256@2x.png", 512, "ic14"),
    ("icon_512x512.png", 512, "ic09"),
    ("icon_512x512@2x.png", 1024, "ic10")
]

var icnsData = Data()
// ICNS Magic: 'icns' (4 bytes) + total length placeholder (4 bytes)
icnsData.append(contentsOf: [0x69, 0x63, 0x6e, 0x73])
icnsData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

for config in iconConfigs {
    let fileURL = iconsetDir.appendingPathComponent(config.name)
    if let pngData = resizeAndSave(image: masterImage, width: config.size, height: config.size, destinationURL: fileURL) {
        let tagBytes = Array(config.tag.utf8)
        let chunkLength = UInt32(pngData.count + 8).bigEndian
        icnsData.append(contentsOf: tagBytes)
        withUnsafeBytes(of: chunkLength) { icnsData.append(contentsOf: $0) }
        icnsData.append(pngData)
    }
}

// Update total ICNS length in header
let totalLength = UInt32(icnsData.count).bigEndian
withUnsafeBytes(of: totalLength) { rawBytes in
    for i in 0..<4 {
        icnsData[4 + i] = rawBytes[i]
    }
}

let icnsURL = resourcesDir.appendingPathComponent("AppIcon.icns")
try? icnsData.write(to: icnsURL)
print("Saved \(icnsURL.path) (size: \(icnsData.count) bytes)")
print("Generated all icon files successfully!")
