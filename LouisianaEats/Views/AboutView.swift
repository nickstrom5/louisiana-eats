import SwiftUI

struct AboutView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("BAYOU EATS").displayFont(32).foregroundStyle(Theme.green)
                    Text("A free guide to \(model.restaurantCount.formatted()) Louisiana restaurants, with MICHELIN and James Beard honors, New Orleans' and East Baton Rouge's license lists, and hand-checked lists of Louisiana's own food: po-boys, Creole dining rooms, boudin, oyster bars and beignets. No account, no ads, no tracking.")
                        .font(.subheadline).foregroundStyle(Theme.ink2)
                    Text("Bayou Eats is an independent app by Nicholas Soderstrom. It is not affiliated with, endorsed by or operated by the State of Louisiana, the Louisiana Department of Health, the Office of Alcohol and Tobacco Control, the City of New Orleans, the City of Baton Rouge and Parish of East Baton Rouge, any parish, Louisiana Travel, the MICHELIN Guide, the James Beard Foundation, Apple, or any restaurant or chain. Other names are trademarks of their owners.")
                        .font(.footnote).foregroundStyle(Theme.muted)
                }
                .padding(.vertical, 4)
            }
            Section("How the lists are built") {
                Text("Hand-checked lists (po-boys, old-line Creole dining rooms, boudin and cracklins, oyster bars and boiled seafood, beignets, and the oldest places) include only places checked against a 2025 or 2026 source (a dated local guide or news story, an official tourism listing or the place's own website), with the address checked. Founding years mean the year it opened at this address.")
                Text("Honors are the MICHELIN Guide American South's 2026 Louisiana selection (Emeril's two stars, one-star restaurants, Bib Gourmands and recommended places), James Beard Foundation winners and America's Classics.")
                Text("Louisiana publishes no open list of its restaurants statewide. This app starts from open map listings (Overture Maps) and keeps the kinds that proved reliable: checked against New Orleans' business licenses and East Baton Rouge Parish's business registrations, high-confidence listings matched far more often than the kinds left out. Those two lists also confirm places, and add licensed restaurants and bars the map data missed. New Orleans' alcohol outlet permits say which places there serve drinks; anywhere else that's unknown, never no. Adult clubs are left out, and truck-stop casinos and video poker parlors are hidden with the non-restaurants. Website links are checked, and any that no longer belong to the place are left out.")
                Text("The Louisiana Department of Health inspects restaurants in every parish. Its reports list critical and non-critical violations, with no score, grade or placard, and they are published only in the department's own search, not as data, so this app shows no inspection results and computes no grade; each place links to the search.")
                Text("Ratings, reviews, hours and photos are Apple Maps' own, shown live in Apple's place card. This app doesn't store or rank by them.")
            }
            .font(.subheadline).foregroundStyle(Theme.ink2)
            Section("Sources") {
                source("City of New Orleans, Bureau of Revenue", "Occupational Business Licenses (data.nola.gov), updated daily, as of \(model.permitsUpdated): restaurants, bars, bakeries and snack bars, modified for use in this app; Alcohol Beverage Outlets (CC0 1.0, last updated August 2025). Owner names are never used.", Links.licenses.absoluteString)
                source("City of Baton Rouge and Parish of East Baton Rouge", "Businesses Registered with EBR Parish and ABC_License (data.brla.gov), public domain, modified for use in this app.", "https://data.brla.gov/d/xw6s-bcqm")
                source("Louisiana Department of Health", "Retail food inspection reports, in the department's own search. Linked from each place; not copied.", Links.inspections.absoluteString)
                source("Overture Maps Foundation", "Restaurant listings and websites come from Overture Maps Foundation places data (overturemaps.org)\(model.overtureRelease.map { ", release \($0)" } ?? ""), filtered and reformatted for this app.\n• Data from Meta, Microsoft, DAC and BrightQuery. Available under CDLA Permissive 2.0.\n• Data from Foursquare. \(foursquareCopyright) Available under Apache 2.0. Foursquare data was transformed to the Overture schema; this app further filtered and reformatted it. See the NOTICE below.\n• Data from AllThePlaces. Available under CC0 1.0.\nResearched places are put on the map with Overture Maps addresses data (open address sources under permissive licenses, docs.overturemaps.org/attribution).", "https://overturemaps.org")
                source("Honors", "The MICHELIN Guide American South selection and James Beard Foundation awards and America's Classics are reported as facts and checked by hand against the official announcements. MICHELIN and the MICHELIN Guide are trademarks of Michelin. James Beard Foundation and James Beard Award are trademarks of the James Beard Foundation. Other names belong to their owners.", "https://guide.michelin.com/us/en/louisiana/restaurants")
                source("Maps", "Maps, place cards and directions by Apple Maps.", nil)
            }
            Section("Licenses") {
                NavigationLink("Community Data License Agreement – Permissive 2.0") { LicenseText(file: "CDLA-Permissive-2.0", title: "CDLA Permissive 2.0") }
                NavigationLink("Apache License 2.0") { LicenseText(file: "Apache-2.0", title: "Apache License 2.0") }
                NavigationLink("Foursquare OS Places NOTICE") { LicenseText(file: "Foursquare-NOTICE", title: "Foursquare NOTICE") }
            }
            Section("Privacy") {
                Text("The app collects nothing. Your location, if you allow it, only sorts lists by distance and shows where you are on the map, on this device. Saved places stay on this device.")
                    .font(.subheadline).foregroundStyle(Theme.ink2)
                DataUpdatesNote()
                    .font(.footnote).foregroundStyle(Theme.muted)
                Link("Privacy policy", destination: Links.privacy)
                Link("Terms of use", destination: Links.terms)
            }
            Section("Help") {
                Link("Report a missing or closed place", destination: Links.correctionEmail)
                Link("Email \(Links.supportEmail)", destination: URL(string: "mailto:\(Links.supportEmail)")!)
                Link("Website", destination: Links.site)
                Text("Data as of \(DayFormat.text(model.generated) ?? model.generated). Places open and close; check before you go. Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                    .font(.footnote).foregroundStyle(Theme.muted)
            }
        }
        .navigationTitle("About")
        .tint(Theme.green)
    }

    /// the copyright line exactly as the bundled Foursquare NOTICE has it, so the two can't disagree
    private var foursquareCopyright: String {
        guard let url = Bundle.main.url(forResource: "Foursquare-NOTICE", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8),
              let line = text.split(separator: "\n").first(where: { $0.hasPrefix("©") }) else { return "© Foursquare Labs, Inc. All rights reserved." }
        return line.trimmingCharacters(in: .whitespaces)
    }

    @ViewBuilder
    private func source(_ name: String, _ detail: String, _ url: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let url, let u = URL(string: url) { Link(name, destination: u).font(.subheadline.weight(.semibold)) }
            else { Text(name).font(.subheadline.weight(.semibold)) }
            Text(detail).font(.caption).foregroundStyle(Theme.muted)
        }
    }
}

/// A bundled license text (Resources/Licenses), reflowed rather than shown as raw 80-column lines.
struct LicenseText: View {
    let file: String
    let title: String

    var body: some View {
        ScrollView {
            Text(text).font(.footnote).foregroundStyle(Theme.ink).textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading).padding()
        }
        .inlineTitle(title)
    }

    private var text: String {
        guard let url = Bundle.main.url(forResource: file, withExtension: "txt"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else { return "License text missing." }
        // join hard-wrapped lines into paragraphs; keep blank lines and list items as breaks
        var out: [String] = []
        for para in raw.components(separatedBy: "\n\n") {
            let lines = para.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
            var joined = ""
            for l in lines where !l.isEmpty {
                let startsItem = l.hasPrefix("–") || l.hasPrefix("-") || l.range(of: #"^\(?[a-z0-9]{1,3}[.)]\s"#, options: .regularExpression) != nil
                joined += joined.isEmpty ? l : (startsItem ? "\n" + l : " " + l)
            }
            if !joined.isEmpty { out.append(joined) }
        }
        return out.joined(separator: "\n\n")
    }
}
