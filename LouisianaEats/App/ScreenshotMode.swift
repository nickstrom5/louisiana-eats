import Foundation
import CoreLocation
import UIKit

/// `-screenshot <name>` opens one screen with fixed state for App Store screenshots (scripts/capture-screenshots.sh).
/// Names: home, poboys, creole, boudin, seafood, sweets, honors, oldest, detail, map, saved, about.
enum ScreenshotMode {
    /// Debug builds only: an App Store build ignores the launch argument, so no one can reach seeded screens or fake locations.
    static var name: String? {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-screenshot"), i + 1 < args.count else { return nil }
        return args[i + 1]
        #else
        return nil
        #endif
    }
    static var isActive: Bool { name != nil }

    @MainActor
    static func apply(to model: AppModel) {
        guard let name, model.isLoaded else { return }
        model.filters = Filters()
        // the French Quarter (Jackson Square), so "nearest" lists have distances without a permission prompt
        model.screenshotLocation = CLLocation(latitude: 29.9575, longitude: -90.0630)
        // by name and town, ignoring case, so a rebuild with a slightly different casing still finds the place; the hand-checked one first
        let pick = { (n: String, town: String?) -> Place? in
            let hits = model.places.filter { $0.name.caseInsensitiveCompare(n) == .orderedSame && (town == nil || $0.city == town) }
            return hits.first(where: \.handChecked) ?? hits.first
        }
        for p in [pick("Dooky Chase", "New Orleans"), pick("Parkway Bakery & Tavern", "New Orleans"), pick("Emeril's", "New Orleans")]
            .compactMap({ $0 }) where !model.isSaved(p) {
            model.toggleSaved(p)
        }
        let open = { (g: Guide) in model.tab = .guides; model.selectedGuide = g; model.guidesPath = [.guide(g)] }
        switch name {
        case "poboys": open(.poboys)
        case "creole": open(.creole)
        case "boudin":
            // from Scott, the self-styled boudin capital, west of Lafayette
            model.screenshotLocation = CLLocation(latitude: 30.2363, longitude: -92.0946)
            open(.boudin)
        case "seafood": open(.seafood)
        case "sweets": open(.sweets)
        case "honors": open(.honors)
        case "oldest": open(.oldest)
        case "detail":
            // Dooky Chase's in Tremé: hand-checked, a Bib Gourmand and a James Beard America's Classic, with its note
            open(.creole)
            if let p = pick("Dooky Chase", "New Orleans") ?? model.places.first {
                model.selectedPlace = p; model.guidesPath.append(.place(p))
            }
        case "map": model.tab = .map
        case "saved": model.tab = .saved
        case "about": model.tab = .about
        default: model.tab = .guides; model.selectedGuide = nil
        }
        // iPad shows the place column next to every list, so give each shot a place instead of "Pick a place": a different
        // honored or hand-checked one per shot.
        guard UIDevice.current.userInterfaceIdiom == .pad, model.selectedPlace == nil else { return }
        let place: Place? = switch name {
        case "home": pick("Galatoire's", "New Orleans")
        case "poboys": pick("Parkway Bakery & Tavern", "New Orleans")
        case "creole": pick("Dooky Chase", "New Orleans")
        case "boudin": pick("Billy's Boudin & Cracklins", "Scott")
        case "seafood": pick("Acme Oyster House", "New Orleans")
        case "sweets": pick("Cafe Du Monde", "New Orleans")
        case "map": pick("Emeril's", "New Orleans")
        case "honors": pick("Emeril's", "New Orleans")
        case "oldest": pick("Mosca's Restaurant", "Westwego")
        case "saved": pick("Parkway Bakery & Tavern", "New Orleans")
        case "about": nil
        default: pick("Commander's Palace", "New Orleans")
        }
        model.selectedPlace = place
    }
}
