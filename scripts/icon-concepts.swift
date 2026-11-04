// Bayou Eats icon concepts (2026-11-03), drawn in the shared Eats Ranked style (state-prompts/ICON-STYLE.md): one flat, level, centred
// food on cypress green #2F5D50, no backing shape, no text or texture, no fleur-de-lis.
//   A  three beignets under powdered sugar
//   B  a boiled crawfish, bright red, seen from above
// Usage, from la-eats/: swift scripts/icon-concepts.swift <out dir>   -> concept-{a,b}-1024.png
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
}
let CYPRESS: UInt32 = 0x2F5D50

/// A: three square beignets in a pyramid, golden with a darker fried edge, white sugar on top. CoreGraphics y-up.
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

/// B: a boiled crawfish from above: tail fan, banded tail, body, two claws, eyes.
func crawfish(_ c: CGContext, _ s: CGFloat) {
    func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
    c.setFillColor(rgb(0xD7261E))
    c.fillEllipse(in: CGRect(x: 0.40 * s, y: 0.42 * s, width: 0.20 * s, height: 0.30 * s))           // body
    for (i, w) in [0.18, 0.16, 0.14, 0.12].enumerated() {                                                // tail segments
        c.fillEllipse(in: CGRect(x: (0.5 - w / 2) * s, y: (0.36 - CGFloat(i) * 0.06) * s, width: w * s, height: 0.08 * s))
    }
    let fan = CGMutablePath(); fan.move(to: P(0.5, 0.20)); fan.addLine(to: P(0.40, 0.14)); fan.addLine(to: P(0.60, 0.14)); fan.closeSubpath()
    c.addPath(fan); c.fillPath()
    c.fillEllipse(in: CGRect(x: 0.20 * s, y: 0.70 * s, width: 0.16 * s, height: 0.12 * s))           // claws
    c.fillEllipse(in: CGRect(x: 0.64 * s, y: 0.70 * s, width: 0.16 * s, height: 0.12 * s))
    c.setStrokeColor(rgb(0xD7261E)); c.setLineWidth(0.035 * s); c.setLineCap(.round)
    c.move(to: P(0.44, 0.68)); c.addLine(to: P(0.32, 0.74)); c.strokePath()
    c.move(to: P(0.56, 0.68)); c.addLine(to: P(0.68, 0.74)); c.strokePath()
    c.setFillColor(rgb(0x1B1B1B))
    c.fillEllipse(in: CGRect(x: 0.45 * s, y: 0.66 * s, width: 0.03 * s, height: 0.03 * s)); c.fillEllipse(in: CGRect(x: 0.52 * s, y: 0.66 * s, width: 0.03 * s, height: 0.03 * s))
}

func render(_ n: Int, _ path: String, _ draw: (CGContext, CGFloat) -> Void) {
    let ctx = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.setShouldAntialias(true)
    ctx.setFillColor(rgb(CYPRESS)); ctx.fill(CGRect(x: 0, y: 0, width: n, height: n))
    draw(ctx, CGFloat(n))
    let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, ctx.makeImage()!, nil)
    guard CGImageDestinationFinalize(d) else { fatalError("could not write \(path)") }
    print("wrote", path)
}
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "playbook/brand"
render(1024, out + "/concept-a-1024.png", beignets)
render(1024, out + "/concept-b-1024.png", crawfish)
