#!/usr/bin/env swift
//
//  Draws the AIRewriteAnywhere mark and rasterises every size the app and the website need.
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

private let ink = NSColor(srgbRed: 0.055, green: 0.065, blue: 0.09, alpha: 1)      // near-black tile
private let accent = NSColor(srgbRed: 0.40, green: 0.78, blue: 1.0, alpha: 1)      // sky
private let accentDeep = NSColor(srgbRed: 0.30, green: 0.55, blue: 1.0, alpha: 1)  // deeper sky
private let paper = NSColor(srgbRed: 0.99, green: 0.99, blue: 1.0, alpha: 1)

// MARK: - Drawing

/// Everything is expressed in a 1024×1024 design space and scaled, so one routine serves all sizes.
private func drawMark(in size: CGFloat, tile: Bool) {
    let s = size / 1024.0
    func p(_ value: CGFloat) -> CGFloat { value * s }

    NSGraphicsContext.current?.imageInterpolation = .high

    if tile {
        // macOS icons sit in a rounded square with generous padding around the artwork.
        let inset = p(96)
        let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
        let tilePath = NSBezierPath(roundedRect: rect, xRadius: p(200), yRadius: p(200))

        ink.setFill()
        tilePath.fill()

        // A very soft top-light so the tile doesn't read as flat black.
        NSGraphicsContext.saveGraphicsState()
        tilePath.addClip()
        let sheen = NSGradient(colors: [NSColor.white.withAlphaComponent(0.10),
                                        NSColor.white.withAlphaComponent(0.0)])
        sheen?.draw(in: rect, angle: 90)
        NSGraphicsContext.restoreGraphicsState()
    }

    // MARK: Caret — the "this is text" cue.
    let caretWidth = p(70)
    let caretHeight = p(430)
    let caretX = size / 2 - p(205)
    let caretY = size / 2 - caretHeight / 2 - p(6)

    let caret = NSBezierPath(roundedRect: NSRect(x: caretX, y: caretY, width: caretWidth, height: caretHeight),
                             xRadius: caretWidth / 2, yRadius: caretWidth / 2)
    (tile ? paper : ink).setFill()
    caret.fill()

    // Serif-style caret arms, top and bottom, so it reads as a text cursor rather than a bar.
    let armWidth = p(210)
    let armHeight = p(66)
    for armY in [caretY - armHeight / 2 + p(8), caretY + caretHeight - armHeight / 2 - p(8)] {
        let arm = NSBezierPath(roundedRect: NSRect(x: caretX + caretWidth / 2 - armWidth / 2,
                                                   y: armY,
                                                   width: armWidth, height: armHeight),
                               xRadius: armHeight / 2, yRadius: armHeight / 2)
        (tile ? paper : ink).setFill()
        arm.fill()
    }

    // MARK: Sparkle — the "AI" cue. A four-point star built from concave curves.
    func sparkle(centre: CGPoint, radius: CGFloat, waist: CGFloat) -> NSBezierPath {
        let path = NSBezierPath()
        let w = radius * waist
        path.move(to: CGPoint(x: centre.x, y: centre.y + radius))
        path.curve(to: CGPoint(x: centre.x + radius, y: centre.y),
                   controlPoint1: CGPoint(x: centre.x + w, y: centre.y + w),
                   controlPoint2: CGPoint(x: centre.x + w, y: centre.y + w))
        path.curve(to: CGPoint(x: centre.x, y: centre.y - radius),
                   controlPoint1: CGPoint(x: centre.x + w, y: centre.y - w),
                   controlPoint2: CGPoint(x: centre.x + w, y: centre.y - w))
        path.curve(to: CGPoint(x: centre.x - radius, y: centre.y),
                   controlPoint1: CGPoint(x: centre.x - w, y: centre.y - w),
                   controlPoint2: CGPoint(x: centre.x - w, y: centre.y - w))
        path.curve(to: CGPoint(x: centre.x, y: centre.y + radius),
                   controlPoint1: CGPoint(x: centre.x - w, y: centre.y + w),
                   controlPoint2: CGPoint(x: centre.x - w, y: centre.y + w))
        path.close()
        return path
    }

    let bigCentre = CGPoint(x: size / 2 + p(150), y: size / 2 + p(138))
    let big = sparkle(centre: bigCentre, radius: p(232), waist: 0.30)

    if tile {
        NSGraphicsContext.saveGraphicsState()
        big.addClip()
        let gradient = NSGradient(colors: [accent, accentDeep])
        gradient?.draw(in: big.bounds, angle: -60)
        NSGraphicsContext.restoreGraphicsState()
    } else {
        accentDeep.setFill()
        big.fill()
    }

    // A small companion sparkle gives the mark a little life without adding clutter.
    let small = sparkle(centre: CGPoint(x: size / 2 + p(288), y: size / 2 - p(200)),
                        radius: p(90), waist: 0.30)
    (tile ? accent : accentDeep).setFill()
    small.fill()
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
                let alpha = colour.alphaComponent
                let luma = (0.2126 * colour.redComponent
                            + 0.7152 * colour.greenComponent
                            + 0.0722 * colour.blueComponent) * alpha
                total += luma
                samples += 1
            }
            let luma = samples > 0 ? total / samples : 0
            // The tile itself is dark but not black; drop it to blank so only the mark prints.
            let floor = 0.20
            let normalized = max(0, (luma - floor) / (1 - floor))
            let index = min(ramp.count - 1, Int(normalized * Double(ramp.count)))
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
