import SwiftUI
import UIKit
import CoreText

/// Louisiana bayou palette (provisional, 2026-11-03; Nick decides, playbook/05-naming.md), light only: cypress green #2F5D50 (7.5:1 on
/// white) for titles, tint and accents; crawfish red #B5121B (white on it 6.9:1) for the hand-checked guide cards under white text and
/// for MICHELIN chips; old gold #D3BC8D only as a pin and card fill under dark text (gold text on white is 1.9:1, so never text on it);
/// moss-cream #F4EFE6 surfaces. No purple-and-gold (LSU vs. Tulane splits the state) and no fleur-de-lis. The names `green`/`gold` are
/// kept from Wisconsin Eats so the shared views read the same; here `green` is cypress and `gold` is crawfish red.
enum Theme {
    static let green = Color(hex: 0x2F5D50)      // cypress: titles, tint, primary text accents
    static let green2 = Color(hex: 0x3E7464)
    static let gold = Color(hex: 0xB5121B)       // crawfish red: card fills under white text, chips
    static let goldSoft = Color(hex: 0xF6D9D6)   // soft red
    static let lime = Color(hex: 0xD3BC8D)       // old gold, fills only (hand-checked pins, the title shadow), under dark text
    static let limeSoft = Color(hex: 0xF1E8D4)
    static let sand = Color(hex: 0xF4EFE6)       // the Home background, moss-cream
    static let red = Color(hex: 0xB5121B)        // MICHELIN chips
    static let ink = Color(hex: 0x18231F)
    static let ink2 = Color(hex: 0x2F3D37)
    static let muted = Color(hex: 0x58635E)
    static let surface = Color.white
    static let surface2 = Color(hex: 0xEFEADF)
    static let surface3 = Color(hex: 0xE4DDCF)
    static let rule = Color(hex: 0xE4DDCF)
    static let rule2 = Color(hex: 0xCEC4B1)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

/// A small uppercase label: "STONE CRAB", "1 MICHELIN STAR".
struct Chip: View {
    enum Style { case gold, green, red, plain, dashed }
    let text: String
    var style: Style = .plain

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(0.4)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .foregroundStyle(style == .green || style == .red ? Color.white : style == .dashed ? Theme.muted : style == .gold ? Theme.ink : Theme.green)
            .background {
                RoundedRectangle(cornerRadius: 5).fill(style == .gold ? Theme.goldSoft : style == .green ? Theme.green : style == .red ? Theme.red
                                                       : style == .dashed ? .clear : Theme.surface2)
            }
            .overlay {
                if style == .dashed { RoundedRectangle(cornerRadius: 5).strokeBorder(Theme.rule2, style: StrokeStyle(lineWidth: 1, dash: [3, 2])) }
            }
            .accessibilityLabel(text)
    }
}

/// Bayou Eats' lettering: the system face drawn compressed and heavy for titles and guide names (like a show poster), and the
/// system monospaced face for numbers, dates and small labels. No bundled fonts.
struct DisplayFont: ViewModifier {
    let size: CGFloat
    var weight: Font.Weight = .black
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content.font(.system(size: size * min(scale, 1.6), weight: weight).width(.compressed))
    }
}

/// Numbers, dates and small labels in the system monospaced face, scaled like DisplayFont.
struct MonoFont: ViewModifier {
    let size: CGFloat
    var weight: Font.Weight = .semibold
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content.font(.system(size: size * min(scale, 1.6), weight: weight, design: .monospaced))
    }
}

extension View {
    func displayFont(_ size: CGFloat, weight: Font.Weight = .black) -> some View {
        modifier(DisplayFont(size: size, weight: weight))
    }

    func monoFont(_ size: CGFloat, weight: Font.Weight = .semibold) -> some View {
        modifier(MonoFont(size: size, weight: weight))
    }
}

/// The header band: a French Quarter cast-iron gallery railing, cypress balusters with a scroll between each pair, over a red rail.
struct Stripes: View {
    var height: CGFloat = 6

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height, band = max(3, h * 0.24)
            let top = max(2, h * 0.12), step = max(10, h * 0.62)
            ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: top)), with: .color(Theme.green))
            var x: CGFloat = step / 2
            while x < w {
                ctx.fill(Path(CGRect(x: x - 1, y: top, width: 2, height: h - band - top)), with: .color(Theme.green))
                let r = min(step * 0.22, (h - band - top) * 0.3)
                ctx.stroke(Path(ellipseIn: CGRect(x: x + step / 2 - r, y: (h - band + top) / 2 - r, width: 2 * r, height: 2 * r)),
                           with: .color(Theme.green), lineWidth: 1.5)
                x += step
            }
            ctx.fill(Path(CGRect(x: 0, y: h - band, width: w, height: band)), with: .color(Theme.gold))
        }
        .frame(height: height * 3.4)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .accessibilityHidden(true)
    }
}

extension View {
    /// An inline navigation title in the display type. UINavigationBar.appearance() didn't reach every SwiftUI bar on iOS 27
    /// (the Map title went from compressed blue to plain black after a push and pop; place titles were always plain), so the
    /// title is our own view in the bar. The navigation title is still set, for the back button and VoiceOver.
    func inlineTitle(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title).displayFont(19, weight: .heavy).foregroundStyle(Theme.green)
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .accessibilityAddTraits(.isHeader)
                }
            }
    }
}
