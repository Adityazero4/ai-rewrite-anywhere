#!/usr/bin/env swift
//
//  Draws the PencilMark mark and rasterises every size the app and the website need.
//  Run from the repo root:  swift tools/make-icon.swift
//
//  There is no Xcode and no design tooling on this machine, so the mark is drawn in Core Graphics.
//  That makes it deterministic and re-runnable — change a number here and every asset regenerates.
//
//  The mark: a rounded tile, a text caret, and a sparkle sitting on it. Reads as "AI edits text",
//  survives being shrunk to 16px, and holds up in one colour.
//

import AppKit
import Foundation

// MARK: - Palette

private let ink = NSColor(srgbRed: 0.078, green: 0.078, blue: 0.102, alpha: 1)   // manuscript ink
private let accent = NSColor(srgbRed: 0.122, green: 0.310, blue: 0.847, alpha: 1) // blue pencil
private let accentDeep = NSColor(srgbRed: 0.784, green: 0.204, blue: 0.169, alpha: 1) // red pencil
private let paper = NSColor(srgbRed: 0.988, green: 0.988, blue: 0.980, alpha: 1)  // proof paper

// MARK: - Drawing

/// Everything is expressed in a 1024×1024 design space and scaled, so one routine serves all sizes.
///
/// Pencil Mark's mark: a pencil and a brush crossed, each laying down its own stroke. The pencil
/// is the blue correction, the brush the red strike — the same two hands the website uses to mark
/// up a proof. Crossed tools read as a single silhouette at 16px, which a detailed scene would not.
private func drawMark(in size: CGFloat, tile: Bool) {
    let s = size / 1024.0
    func p(_ value: CGFloat) -> CGFloat { value * s }

    NSGraphicsContext.current?.imageInterpolation = .high

    if tile {
        let inset = p(72)
        let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
        let tilePath = NSBezierPath(roundedRect: rect, xRadius: p(196), yRadius: p(196))
        paper.setFill()
        tilePath.fill()
        NSColor.black.withAlphaComponent(0.12).setStroke()
        tilePath.lineWidth = p(6)
        tilePath.stroke()
    }

    /// Draws an implement along an axis: a shaft, a collar, and a tapered working end.
    /// `lean` is the angle in degrees; everything else is measured along that axis.
    func implement(lean: CGFloat,
                   bodyColour: NSColor,
                   tipColour: NSColor,
                   width: CGFloat,
                   bodyLength: CGFloat,
                   tipLength: CGFloat,
                   squareTip: Bool) {
        NSGraphicsContext.saveGraphicsState()

        let transform = NSAffineTransform()
        transform.translateX(by: size / 2, yBy: size / 2)
        transform.rotate(byDegrees: lean)
        transform.concat()

        let half = width / 2
        let bodyBottom = -bodyLength / 2

        // Shaft.
        let shaft = NSBezierPath(roundedRect: NSRect(x: -half, y: bodyBottom,
                                                     width: width, height: bodyLength),
                                 xRadius: p(20), yRadius: p(20))
        bodyColour.setFill()
        shaft.fill()

        // Collar: the ferrule on a brush, the painted band on a pencil.
        let collar = NSBezierPath(rect: NSRect(x: -half, y: bodyBottom + bodyLength - p(30),
                                                width: width, height: p(58)))
        ink.withAlphaComponent(0.85).setFill()
        collar.fill()

        // Working end.
        let tipBase = bodyBottom + bodyLength + p(28)
        let tip = NSBezierPath()
        if squareTip {
            // A brush splays rather than points.
            tip.move(to: CGPoint(x: -half * 1.18, y: tipBase))
            tip.line(to: CGPoint(x: half * 1.18, y: tipBase))
            tip.line(to: CGPoint(x: half * 0.72, y: tipBase + tipLength))
            tip.line(to: CGPoint(x: -half * 0.72, y: tipBase + tipLength))
        } else {
            // A pencil comes to a point.
            tip.move(to: CGPoint(x: -half, y: tipBase))
            tip.line(to: CGPoint(x: half, y: tipBase))
            tip.line(to: CGPoint(x: 0, y: tipBase + tipLength))
        }
        tip.close()
        tipColour.setFill()
        tip.fill()

        NSGraphicsContext.restoreGraphicsState()
    }

    // Brush leans one way in red, pencil the other in blue. Pencil drawn second so it reads on top.
    implement(lean: 214, bodyColour: accentDeep.blended(withFraction: 0.35, of: paper) ?? accentDeep,
              tipColour: accentDeep, width: p(150), bodyLength: p(430), tipLength: p(120),
              squareTip: true)

    implement(lean: 146, bodyColour: accent.blended(withFraction: 0.30, of: paper) ?? accent,
              tipColour: accent, width: p(150), bodyLength: p(430), tipLength: p(132),
              squareTip: false)
}

// MARK: - Rasterising

private func render(size: Int, tile: Bool, transparent: Bool = true) -> Data {
    let dimension = CGFloat(size)
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                     pixelsWide: size, pixelsHigh: size,
                                     bitsPerSample: 8, samplesPerPixel: 4,
                                     hasAlpha: true, isPlanar: false,
                                     colorSpaceName: .deviceRGB,
                                     bytesPerRow: 0, bitsPerPixel: 0) else {
        fatalError("could not allocate a \(size)px bitmap")
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    if !transparent {
        paper.setFill()
        NSRect(x: 0, y: 0, width: dimension, height: dimension).fill()
    }
    drawMark(in: dimension, tile: tile)

    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("could not encode a \(size)px PNG")
    }
    return data
}

private func write(_ data: Data, to path: String) {
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                             withIntermediateDirectories: true)
    try! data.write(to: url)
    print("  \(path)  (\(data.count / 1024) KB)")
}

// MARK: - Outputs

let root = FileManager.default.currentDirectoryPath
let iconset = "\(root)/.build/AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconset)
try! FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)

print("macOS iconset:")
// The exact filenames `iconutil` expects.
let iconSizes: [(name: String, pixels: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
for (name, pixels) in iconSizes {
    write(render(size: pixels, tile: true), to: "\(iconset)/\(name).png")
}

print("\nWeb icons:")
// Next.js App Router picks these up by filename and emits the tags itself.
write(render(size: 512, tile: true), to: "\(root)/apps/web/app/icon.png")
write(render(size: 180, tile: true), to: "\(root)/apps/web/app/apple-icon.png")
write(render(size: 1024, tile: true), to: "\(root)/apps/web/public/app-icon.png")

// MARK: - ASCII

/// The mark, rendered as characters. Generated from the same drawing routine as every other
/// asset, so it can never drift from the icon. Used in the README and the build banner.
func asciiArt(columns: Int) -> String {
    // Character cells are roughly twice as tall as they are wide, so two pixel rows per text row.
    let rows = columns / 2
    let pixels = columns

    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                     pixelsWide: pixels, pixelsHigh: pixels,
                                     bitsPerSample: 8, samplesPerPixel: 4,
                                     hasAlpha: true, isPlanar: false,
                                     colorSpaceName: .deviceRGB,
                                     bytesPerRow: 0, bitsPerPixel: 0) else { return "" }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    drawMark(in: CGFloat(pixels), tile: true)
    NSGraphicsContext.restoreGraphicsState()

    let ramp = Array(" .:-=+*#%@")
    var lines: [String] = []

    for row in 0..<rows {
        var line = ""
        for column in 0..<pixels {
            // Average the two source rows this text row covers.
            var total = 0.0
            var samples = 0.0
            for dy in 0..<2 {
                let y = row * 2 + dy
                guard y < pixels, let colour = rep.colorAt(x: column, y: y) else { continue }
                // The tile is paper with dark marks on it, so density tracks *darkness*.
                // Anything outside the rounded tile is transparent and stays blank.
                guard colour.alphaComponent > 0.5 else { continue }
                let luma = 0.2126 * colour.redComponent
                         + 0.7152 * colour.greenComponent
                         + 0.0722 * colour.blueComponent
                total += 1.0 - luma
                samples += 1
            }
            let darkness = samples > 0 ? total / samples : 0
            // Paper is not pure white; lift the floor so the sheet itself stays blank.
            let floor = 0.12
            let normalized = max(0, (darkness - floor) / (1 - floor))
            let index = min(ramp.count - 1, Int(normalized * Double(ramp.count) * 1.35))
            line.append(ramp[index])
        }
        lines.append(line.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression))
    }

    return lines.joined(separator: "\n")
}

print("\nASCII mark:")
let ascii = asciiArt(columns: 56)
print(ascii)
write(Data(ascii.utf8), to: "\(root)/tools/logo.txt")

print("\nDone. Now run: iconutil -c icns \(iconset) -o apps/macos/Resources/AppIcon.icns")
