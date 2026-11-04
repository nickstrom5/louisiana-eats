# Louisiana Eats (la-eats) — notes for Claude Code sessions

Built 2026-11-03 by a side session while Nick was away, after Rhode Island, ported from `../ga-eats/` (the newest state) with the
10-29 all-states QA P0/P1 fixes in from the start. Local only: no git repo, no remote, nothing published. Sources and calibration:
`playbook/12-sources.md`. Brand: `playbook/05-naming.md` — **provisional**, every choice waits for Nick ("Bayou Eats: Louisiana
Restaurants", Home Screen "Bayou Eats" because "Louisiana Eats!" is WWNO's radio show; beignet icon A on cypress green; cypress
#2F5D50, crawfish red #B5121B, old gold #D3BC8D fill only, moss-cream #F4EFE6; a gallery railing over a red rail).

## Louisiana is different
- **Parishes, not counties.** Every visible string says "parish" (the data files still call the field `county`). 64 parishes from
  Overture's division areas, small islands kept (Grand Isle, the Chandeleurs, Grand Terre).
- **Regions** (9, `louisiana.py`): New Orleans (the main one, with its city page), Northshore, Baton Rouge, Acadiana, Houma & Bayou
  Country, Lake Charles & Southwest, Central Louisiana, Shreveport & Northwest, Monroe & Northeast. The app ships one detail file per
  region.
- **Official records are city lists** (`official.py`): New Orleans Occupational Business Licenses (`load_nola`, food types only, owner
  fields never requested) and Alcohol Beverage Outlets (`load_abo`, on-premises types mean "serves alcohol"); East Baton Rouge NAICS
  722 registrations (`load_ebr`) and ABC licenses (`load_ebrabc`, kind "retail": confirms a place, never adds one or says "serves
  alcohol" because the list doesn't say on- or off-premises). Elsewhere the keep rule is the calibrated map-data rule.
- Inspections: LDH Retail Food Program, statewide, no score or grade; every place links `la.healthinspections.us`. Not harvested
  (Nick's call); a records request under La. R.S. 44:1 is Nick's to send.
- MICHELIN American South 2026, Louisiana (40, read through Claude's fetcher; `MI_MATCH`/`MI_ADDR` in `build_research.py`). James
  Beard 5. Willie Mae's Scotch House is on the closed list (fire, April 2026).

## Rebuild
```bash
cd pipeline
../.venv/bin/python fetch_overture.py && ../.venv/bin/python fetch_extras.py
../.venv/bin/python listings.py && ../.venv/bin/python geocode_official.py && ../.venv/bin/python geocode_census.py
../.venv/bin/python calibrate.py && ../.venv/bin/python build_research.py && ../.venv/bin/python louisiana.py
LA_APP=1 ../.venv/bin/python louisiana.py && cd .. && cp data/app/places.json data/app/detail-*.json LouisianaEats/Resources/
.venv/bin/python pipeline/check_websites.py --retry-transient   # link verification; re-export after
.venv/bin/python scripts/make-site.py && .venv/bin/python scripts/publish_app_data.py && .venv/bin/python scripts/publish_app_data.py --check
.venv/bin/python scripts/qa-site.py --static
```
- Shared code copied as-is from the newest state: `tracking_params.py`, `publish_app_data.py`, `website_blocklist.json`, the widened
  adult-venue rule (OH + TX, 11-03; the website half leaves out `dejavu`: Déjà Vu Bar & Grill on Dauphine Street and Deja Vu Daiquiris aren't clubs) and the
  delivery-brand `STORE` rule (Burger Den, Banda Burrito, The Meltdown, Tenderfix, Pardon My Cheesesteak, Neighborhood Wings).
- Guides (`build_research.py`, each entry with a dated 2025-26 source on a robots-allowed host): po-boys, old-line Creole dining rooms,
  boudin and cracklins, oyster bars and boiled seafood, beignets and snoballs, meat pies, gumbo, oldest. Misses and blocked hosts:
  `data/research/app/LEADS.md`.
- Venues hidden as not-restaurants include truck-stop casinos and airport concourses (`louisiana.py`). Daiquiri shops (187 in
  the app, many drive-through) are kept as bars for now: Nick's call.

## App, site, screenshots
- App: `LouisianaEats/` (XcodeGen `project.yml`, bundle `com.louisianaeats.ios`), tests in `LouisianaEatsTests/` (data guards: adult
  venues, blocklisted and multi-URL websites, bad and legal names, non-restaurants, listed twice, no Google data; Bib Gourmand filter).
  Run tests: `DEVELOPER_DIR="/Applications/Xcode 1.app/Contents/Developer" xcodebuild test ... CODE_SIGNING_ALLOWED=NO` on a temporary
  simulator. Archive only with Xcode 1.app (27.1, 27A9275); Xcode.app is a beta.
- Site: `scripts/make-site.py` writes `docs/` and `playbook/site-numbers.json`; `scripts/explore.js` is the web app; `scripts/qa-site.py`
  the QA. Site URL for now: nickstrom5.github.io/louisiana-eats (no CNAME).
- OTA data: `docs/data/app/` via `scripts/publish_app_data.py` (`../OTA-DATA.md`).
- Screenshots: `scripts/capture-screenshots.sh <sim>` (ScreenshotMode pins the French Quarter, Scott for boudin), then
  `scripts/site-images.sh`, then make-site + qa-site. App Store frames: `scripts/appstore-screenshots.py`.
  Rebuild the site before the unit tests: `ShareLinkTests` reads the web app's ids from `docs/`. Run `xcodegen generate` whenever
  the set of `Resources/*.json` files changes (the project lists only the files it found).
- Last run 2026-11-04: 52 unit tests passed (temporary iPhone 17 Pro Max, iOS 27.0, Xcode 1.app); screenshots from the same data.
- Not ported: the App Store listing writer (`make-listing.py`) and the private Google-2021 leaderboard (`make-leaderboard.py`).
  `site/` holds the leaderboard's data and is git-ignored with `data/`.

## Rules
No commits, pushes, public repos, App Store Connect or DNS changes without Nick's yes each time; never submit for review or accept
agreements; never publish Google-derived data. Support email nick@eatsranked.com. Commit author "Nick Soderstrom"
<329204362+nickstrom5@users.noreply.github.com> via `-c user.name -c user.email`.
