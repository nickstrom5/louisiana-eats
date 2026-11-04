# Louisiana sources (checked 2026-11-03)

Every host below was robots-checked with `pipeline/check_sources.py` (ClaudeBot, Claude-User and anthropic-ai; RFC 9309 matcher) in
its own step, before any other request. User agent on every scripted request: `LouisianaEatsBuild/1.0 (+nick@eatsranked.com)`.
Raw files are in `data/raw/official/` (git-ignored, never public); `socrata_meta.json` keeps each dataset's own update date.

Louisiana has one food inspector and no grade, and no statewide restaurant or alcohol list a script may read. New Orleans and
East Baton Rouge publish their own license lists, which mark places official, add licensed places the map data misses, and (in New
Orleans) say which places serve drinks. The app says "parish", never "county".

## Inspections: one inspector, no grade (linked, never copied)

- **Who inspects:** the Louisiana Department of Health (LDH), Office of Public Health, Retail Food Program, in all 64 parishes, New
  Orleans included (the prompt's research, 2026-09-27; nothing found since says otherwise).
- **What a report says:** critical and non-critical violations marked corrected or repeat. **No score, grade or placard**: the app
  and site compute none and copy none.
- **Where:** `la.healthinspections.us` (Tyler Technologies' search app over an undocumented JSON API; robots: no file, usable).
  **Not harvested**: the prompt makes a harvest Nick's call (one request at a time, honest UA). The records-request route (La. R.S. 44:1)
  is Nick's to send. Every place links the search; the home page answers 200.
- `ldh.la.gov` answers scripts with a bot check (never worked around); `eatsafe.la.gov` only redirects there.
- **History only:** East Baton Rouge "Retail Food Inspections" (data.brla.gov `ux2t-b9wr`, public domain, LDH violations 2020-2025,
  rows updated 2025-10-17): not used for anything shown.

## Official records

| Source | What | Terms | Updated | Status |
|---|---|---|---|---|
| **New Orleans "Occupational Business Licenses"** (data.nola.gov `hjcd-grvu`, Bureau of Revenue) | 4,340 food-type licenses downloaded (owner fields never requested): full-service 1,796, limited-service 647, drinking places 663, snack bars 104, bakeries 124, cafeterias 27, plus caterers, trucks and contractors (kind "other"/"truck") | No license on the dataset; a public record | daily (2026-11-03) | **used**: 3,339 places to eat or drink; 1,447 matched to a map listing, 358 added from the license list (name says food or drink, a point, not a company name) |
| **New Orleans "Alcohol Beverage Outlets"** (`qfg2-kjjz`) | 1,484 outlets with the outlet's business type | CC0 1.0 | 2025-08-17 (says weekly) | **used**: a restaurant, bar, brewery or theater type means drinks are served there (667 app places); store types never do |
| **East Baton Rouge "Businesses Registered with EBR Parish"** (data.brla.gov `xw6s-bcqm`, Finance Department) | NAICS 722000 food services and drinking places: 1,826 open, 2,782 closed, with a point | Public domain | daily (2026-11-03) | **used**: open ones confirm listings (855) and add licensed places (175) |
| **East Baton Rouge "ABC_License"** (`xhjf-mdnv`) | 1,032 parish alcohol licenses with a point | Public domain | 2026-08-11 | **used to confirm a place only**: the list doesn't say package or on-premises, so it never adds a place or says "serves alcohol" |
| ATC "Search For Issued Licenses" (laatcabc.atc.la.gov) | Statewide alcohol licenses | — | — | not used: search-only behind Cloudflare; a records request is Nick's call |
| Jefferson, Lafayette, Caddo, Calcasieu | — | — | — | no open license lists found in this pass (a gap to look at again) |
| Property values | Only East Baton Rouge's tax roll is open | — | — | skipped |

## Statewide base and outlines

| Source | What | Terms | Rows |
|---|---|---|---|
| Overture Maps places `2026-10-21.0` | Map listings; parish (county) and state outlines from land division areas, small islands kept (Grand Isle, the Chandeleurs, Grand Terre) | CDLA-Permissive-2.0 / Apache-2.0 + Foursquare NOTICE; outlines ODbL (© OpenStreetMap contributors, Overture) | 22,237 Louisiana eating/drinking listings (1,033 marked closed); 64 parishes; state outline 616 rings |
| Overture addresses `2026-10-21.0` | 539,150 Louisiana address points | open address sources | placed 144 license rows without a point |
| US Census batch geocoder | Address to point | Public domain | 61 of 127 more |
| UCSD Google Local 2021 (`meta-Louisiana.json.gz`, 14 MB) | 2021 ratings/reviews/price: **private web leaderboard only, never the app or site** | research dataset | 13,219 food listings (1,599 closed by 2021); 9,798 matched |
| Census CBP 2023 (from the prompt) | 9,521 NAICS 722 establishments | public | benchmark: the app keeps 11,338 restaurants |

## Calibration (2026-11-03, `data/la/calibration*.json`)

| Kind of listing (app grouping) | New Orleans, on a business license | East Baton Rouge, on an open NAICS 722 registration | Open in Google 2021 (statewide) |
|---|---|---|---|
| Meta >= 0.95 | 71.2% of 1,387 | 70.7% of 875 | 68.0% of 8,517 |
| Meta 0.90-0.95 with a website | 47.7% of 153 | 48.0% of 177 | 49.6% of 1,953 |
| Meta 0.90-0.95, no website | 28.6% of 63 | 27.8% of 72 | 17.7% of 1,074 |
| Meta < 0.90 | 20.9% of 446 | 24.9% of 265 | 4.6% of 3,316 |
| Chain store lists (AllThePlaces, DAC) | 63.2% of 19 | 44.7% of 47 | 22.4% of 340 |
| BrightQuery >= 0.95 | 44.3% of 291 | 24.0% of 167 | 33.7% of 1,266 |
| Other sources (Foursquare, Microsoft, ...) | 40.5% of 834 | 9.7% of 566 | 25.7% of 4,604 |

Web grouping: Meta + open in Google 2021 78.1% (New Orleans) and 74.2% (East Baton Rouge); Meta only 34.5% and 38.0%; Foursquare only
24.0% and 5.3%. Same order as Georgia and the other states, so the same keep rules: app = Meta >= 0.95, Meta 0.90-0.95 with a
website, chain store lists, official, hand-checked; web = Meta and chain store lists minus Google-2021-closed, plus official and
hand-checked. Coverage the other way: open map listings hold 50.5% of New Orleans' 2,988 licensed food businesses and 61.2% of East
Baton Rouge's 1,425 open registrations.

## Honors and guides

- **MICHELIN Guide American South**, Louisiana, 2026 selection (read through Claude's fetcher, 2026-11-03; 40 places): Emeril's 2
  Stars; Saint-Germain, Dakar NOLA and Zasu 1 Star; 12 Bib Gourmands; 24 Recommended. 38 matched (Cochon Butcher and Saint Claire have no map listing yet).
  No Green Stars.
- **James Beard** (`data/research/jbf.json`): America's Classics Mosca's (1999), Hansen's Sno-Bliz (2014), Dong Phuong (2018), Dooky
  Chase's (2025) (Wikipedia's list; Willie Mae's Scotch House, 2005, is temporarily closed after a fire per New Orleans & Company, April
  2026, so it's on the closed list); Serigne Mbaye, Dakar NOLA, Best Chef: South 2026 (jamesbeard.org).
- **Hand-checked guides** (`pipeline/build_research.py`): po-boys 7, old-line Creole dining rooms 10 (New Orleans & Company,
  2026-04-07), boudin and cracklins 8 (Lafayette Travel's Cajun Boudin Trail, 2025-01-15), oyster bars and boiled seafood 10 (2026-08-03),
  beignets 7 (2026-08-10), meat pies 1, gumbo 2, oldest 1 (Mosca's, 1946). Leads and blocked hosts: `data/research/app/LEADS.md`.
- Blocked or unusable: nola.com, theadvocate.com, nola.eater.com, southernliving.com, gardenandgun.com, wafb.com, fox8live.com
  (robots); louisianatravel.com, ldh.la.gov, dragosrestaurant.com (bot checks).
