// Bayou Eats brand (provisional, 2026-11-03; Nick picks the name, icon and palette): the app icon is concept A of
// scripts/icon-concepts.swift, three beignets under powdered sugar, on cypress green; the shared Eats Ranked icon style,
// state-prompts/ICON-STYLE.md, no backing shape. No fleur-de-lis (it reads as the Saints' mark).
// Usage, from la-eats/: swift scripts/make-brand.swift   -> LouisianaEats/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png,
// docs/ favicons and touch icons, docs/og.png. scripts/make-site.py draws the same mark as its inline SVG: change both together.
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
}
let CYPRESS: UInt32 = 0x2F5D50, RED: UInt32 = 0xB5121B, CREAM: UInt32 = 0xF4EFE6, GOLD: UInt32 = 0xD3BC8D

/// Three square beignets in a pyramid under powdered sugar. CoreGraphics y-up. Identical to icon-concepts.swift's concept A.
func beignets(_ c: CGContext, _ s: CGFloat) {
    func R(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect { CGRect(x: x * s, y: y * s, width: w * s, height: h * s) }
    func pillow(_ r: CGRect) {
        c.setFillColor(rgb(0xC98A3E)); c.addPath(CGPath(roundedRect: r, cornerWidth: r.width * 0.32, cornerHeight: r.height * 0.32, transform: nil)); c.fillPath()
        let inner = r.insetBy(dx: r.width * 0.06, dy: r.height * 0.06)
        c.setFillColor(rgb(0xE8B866)); c.addPath(CGPath(roundedRect: inner, cornerWidth: inner.width * 0.3, cornerHeight: inner.height * 0.3, transform: nil)); c.fillPath()
        // the sugar: a white cap over the top half, hard edge
        c.saveGState(); c.addPath(CGPath(roundedRect: inner, cornerWidth: inner.width * 0.3, cornerHeight: inner.height * 0.3, transform: nil)); c.clip()
        c.setFillColor(rgb(0xFBF8F2)); c.fillEllipse(in: CGRect(x: inner.minX - inner.width * 0.1, y: inner.midY - inner.height * 0.05, width: inner.width * 1.2, height: inner.height * 1.1))
        c.restoreGState()
    }
    let dy: CGFloat = 0.035   // the pyramid's mass sits low: lift it so the area centroid lands near the centre
    pillow(R(0.15, 0.24 + dy, 0.33, 0.27)); pillow(R(0.52, 0.24 + dy, 0.33, 0.27)); pillow(R(0.335, 0.47 + dy, 0.33, 0.27))
}

func render(_ n: Int, _ path: String, background: Bool) {
    let ctx = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: background ? CGImageAlphaInfo.noneSkipLast.rawValue : CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setShouldAntialias(true)
    if background { ctx.setFillColor(rgb(CYPRESS)); ctx.fill(CGRect(x: 0, y: 0, width: n, height: n)) }
    beignets(ctx, CGFloat(n))
    let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, ctx.makeImage()!, nil)
    guard CGImageDestinationFinalize(d) else { fatalError("could not write \(path)") }
    print("wrote", path)
}
render(1024, "LouisianaEats/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png", background: true)
try? FileManager.default.createDirectory(atPath: "docs", withIntermediateDirectories: true)
for (n, name) in [(512, "icon-512.png"), (192, "icon-192.png"), (180, "apple-touch-icon.png"), (32, "favicon-32.png")] {
    render(n, "docs/" + name, background: true)
}

/// The share image (1200 x 630): cypress, the beignets at the left, the name and tagline at the right, and the app's header band along
/// the bottom: a cast-iron gallery railing over a red rail.
func og(_ path: String) {
    let W = 1200, H = 630
    let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.setShouldAntialias(true)
    ctx.setFillColor(rgb(CYPRESS)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
    ctx.setFillColor(rgb(RED)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: 22))
    ctx.setFillColor(rgb(0x1F433A)); ctx.fill(CGRect(x: 0, y: 62, width: W, height: 6))
    var x: CGFloat = 12
    while x < CGFloat(W) {
        ctx.fill(CGRect(x: x - 2, y: 22, width: 4, height: 42))
        ctx.setStrokeColor(rgb(0x1F433A)); ctx.setLineWidth(3); ctx.strokeEllipse(in: CGRect(x: x + 6, y: 34, width: 14, height: 14))
        x += 28
    }
    ctx.saveGState(); ctx.translateBy(x: 30, y: 80); beignets(ctx, 500); ctx.restoreGState()
    let ns = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = ns
    let title = NSFont(name: "AvenirNextCondensed-Heavy", size: 96) ?? NSFont.boldSystemFont(ofSize: 84)
    let sub = NSFont(name: "AvenirNextCondensed-DemiBold", size: 38) ?? NSFont.boldSystemFont(ofSize: 34)
    NSAttributedString(string: "BAYOU EATS", attributes: [.font: title, .foregroundColor: NSColor.white]).draw(at: NSPoint(x: 580, y: 330))
    NSAttributedString(string: "PO-BOYS, BOUDIN & OYSTERS", attributes: [.font: sub, .foregroundColor: NSColor(srgbRed: 0.827, green: 0.737, blue: 0.553, alpha: 1)]).draw(at: NSPoint(x: 584, y: 272))
    NSGraphicsContext.restoreGraphicsState()
    let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, ctx.makeImage()!, nil)
    guard CGImageDestinationFinalize(d) else { fatalError("could not write \(path)") }
    print("wrote", path)
}
og("docs/og.png")
