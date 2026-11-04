"""Writes data/research/app/*.json (hand-checked Louisiana guides), data/research/michelin.json, jbf.json and closed.json from the
compact lists below. Ported from ga-eats/pipeline/build_research.py.

Each entry cites the 2025-26 page that names it (robots-checked host: check_sources.py). Every page below is dated on its face, or is
an official tourism listing. The address comes from the map listing we already hold for that name in that town (site/louisiana.json),
never from memory; a name that isn't found exactly once in its town (or at the street number given) is left out and listed in
data/research/app/LEADS.md. A place the map data lacks is added only when the dated page prints its street address (ADDR).
Usage: ../.venv/bin/python build_research.py   (then louisiana.py)"""
import json, os, re
from brands import brand_of
from common import norm_name
ROOT = os.path.join(os.path.dirname(__file__), "..")
R = os.path.join(ROOT, "data", "research")
d = json.load(open(os.path.join(ROOT, "site", "louisiana.json")))
C, M = d["cols"], d["meta"]
norm = lambda s: re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]", " ", (s or "").lower().replace("'", "").replace("’", ""))).strip()

# each dated on its face (read 2026-11-03)
MI_LA = "https://guide.michelin.com/us/en/louisiana/restaurants"                                    # the 2026 selection (40 places)
NO_CLASSIC = "https://www.neworleans.com/blog/post/new-orleans-most-iconic-restaurants/"            # 2026-04-07
NO_26DISH = "https://www.neworleans.com/blog/post/26-dishes-to-eat-in-new-orleans-in-2026-according-to-local-experts/"   # 2026-05-11
NO_OYSTERS = "https://www.neworleans.com/blog/post/guide-to-new-orleans-best-oysters/"              # 2026-08-03
NO_BEIGNETS = "https://www.neworleans.com/blog/post/the-ultimate-guide-to-beignets/"                # 2026-08-10
NO_BOIL = "https://www.neworleans.com/blog/post/where-to-eat-boiled-seafood/"                       # 2025-03-13
WWNO_POBOY = "https://www.wwno.org/podcast/where-yeat/2026-07-16/where-yeat-at-backstreet-po-boy-shops-a-new-taste-of-old-new-orleans"   # 2026-07-16
LFT_BOUDIN = "https://www.lafayettetravel.com/blog/stories/post/cajun-boudin-trail/"                 # 2025-01-15
NATCH_LASYONE = "https://natchitoches.com/listing/lasyones-meat-restaurant/"                        # the visitors bureau's current listing
WAC = "https://en.wikipedia.org/wiki/List_of_James_Beard_America%27s_Classics"
JBF26 = "https://www.jamesbeard.org/stories/james-beard-award-winners-2026"

# (name as the source writes it or as our listing spells it, town, street number to pick the location (or None), note, founded,
# founded_note, [sources])
GUIDES = {
 "po-boys": [
  ("Parkway Bakery & Tavern", "New Orleans", None, "Po-boys by Bayou St. John; a MICHELIN Bib Gourmand.", None, None, [MI_LA, NO_CLASSIC]),
  ("Domilise's Po-Boy & Bar", "New Orleans", None, "A family-run Uptown po-boy bar; a MICHELIN Bib Gourmand.", None, None, [MI_LA]),
  ("Killer PoBoys", "New Orleans", None, "Po-boys with unusual fillings; MICHELIN Recommended.", None, None, [MI_LA]),
  ("Guy's Po-Boys", "New Orleans", None, "The shrimp po-boy is the one locals name (New Orleans & Company, May 2026).", None, None, [NO_26DISH]),
  ("North Broad Seafood", "New Orleans", None, "The \u201cBlue Store\u201d: catfish po-boys and boiled crawfish.", None, None, [NO_26DISH]),
  ("Radosta's Restaurant", "Metairie", "249", "A backstreet po-boy shop off Metairie Road, with house-made hot sausage.", None, None, [WWNO_POBOY]),
  ("Parentons Poboys", "New Orleans", "4304", "A backstreet po-boy shop off Jefferson Highway.", None, None, [WWNO_POBOY]),
 ],
 "creole dining room": [
  ("Antoine's Restaurant", "New Orleans", None, "Family-run since 1840, now on St. Louis Street; Oysters Rockefeller.", None, None, [NO_CLASSIC]),
  ("Galatoire's", "New Orleans", None, "Bourbon Street's old-line Creole dining room; MICHELIN Recommended.", None, None, [NO_CLASSIC, MI_LA]),
  ("Arnaud's New Orleans", "New Orleans", "813", "A French Quarter Creole dining room, run by the family's fourth generation.", None, None, [NO_CLASSIC]),
  ("Commander's Palace", "New Orleans", None, "The Garden District's turquoise-and-white Creole institution.", None, None, [NO_CLASSIC]),
  ("Brennan's", "New Orleans", None, "Royal Street breakfast and Bananas Foster.", None, None, [NO_CLASSIC]),
  ("Dooky Chase Restaurant", "New Orleans", "2301", "Leah Chase's Tremé Creole kitchen; a MICHELIN Bib Gourmand and a James Beard America's Classic.", None, None, [NO_CLASSIC, MI_LA]),
  ("Clancy's", "New Orleans", None, "An Uptown Creole bistro near Audubon Park; MICHELIN Recommended.", None, None, [NO_CLASSIC, MI_LA]),
  ("Li'l Dizzy's Cafe", "New Orleans", None, "Creole soul food in Tremé.", None, None, [NO_CLASSIC]),
  ("Broussard's", "New Orleans", None, "A French Quarter Creole restaurant and courtyard, a classic since 1920.", None, None, [NO_CLASSIC]),
  ("Pascal's Manale", "New Orleans", None, "Uptown's home of barbecue shrimp.", None, None, [NO_CLASSIC]),
 ],
 "boudin": [   # the Cajun Boudin Trail (Lafayette Travel, January 2025); markets and restaurants that sell boudin hot
  ("Billy's Boudin & Cracklins", "Scott", "1815", "Boudin balls and cracklins in Scott.", None, None, [LFT_BOUDIN]),
  ("Billy's Boudin & Cracklins", "Lafayette", "106", "Billy's on Pont des Mouton Road.", None, None, [LFT_BOUDIN]),
  ("Don's Specialty Meats", "Carencro", "4120", "Don's in Carencro.", None, None, [LFT_BOUDIN]),
  ("Johnson's Boucaniere", "Lafayette", "1111", "Smoked boudin and smoked meats downtown, from family recipes going back to 1937.", None, None, [LFT_BOUDIN]),
  ("Hebert's Boudin & Cracklins", "Breaux Bridge", "2013", "Boudin and fresh pork cracklins in Breaux Bridge.", None, None, [LFT_BOUDIN]),
  ("Earl's Cajun Market", "Lafayette", "510", "A Southside Cajun market with boudin.", None, None, [LFT_BOUDIN]),
  ("Kartchner's Specialty Meats", "Youngsville", "103", "Kartchner's specialty meats in Youngsville.", None, None, [LFT_BOUDIN]),
  ("The Boudin King", "Jennings", "906", "Boudin in Jennings.", None, None, [LFT_BOUDIN]),
 ],
 "seafood": [   # oyster bars and boiled seafood
  ("Drago's Seafood Restaurant", "Metairie", None, "Charbroiled oysters.", None, None, [NO_OYSTERS]),
  ("Acme Oyster House", "New Orleans", "724", "Oysters raw or chargrilled, on Iberville Street.", None, None, [NO_OYSTERS]),
  ("Felix's Restaurant and Oyster Bar", "New Orleans", "739", "A French Quarter oyster bar.", None, None, [NO_OYSTERS]),
  ("Dickie Brennan's Bourbon House", "New Orleans", None, "A Bourbon Street oyster bar.", None, None, [NO_OYSTERS]),
  ("The Blue Crab", "New Orleans", None, "Oysters, boiled crawfish and crab claws by the lake.", None, None, [NO_OYSTERS]),
  ("Neyow's Creole Cafe", "New Orleans", None, "Chargrilled oysters in Mid-City.", None, None, [NO_OYSTERS]),
  ("Superior Seafood", "New Orleans", None, "Oysters raw, chargrilled, Bienville or Rockefeller on St. Charles Avenue.", None, None, [NO_OYSTERS]),
  ("Peche Seafood Grill", "New Orleans", "800", "A Warehouse District seafood grill; MICHELIN Recommended.", None, None, [NO_OYSTERS, MI_LA]),
  ("Porgy's Seafood Market", "New Orleans", None, "Boiled seafood and oysters near City Park.", None, None, [NO_OYSTERS, NO_BOIL]),
  ("Seaworthy", "New Orleans", None, "Raw and charbroiled oysters.", None, None, [NO_OYSTERS]),
  ("Basin Seafood & Spirits", "New Orleans", None, "Oysters on Magazine Street.", None, None, [NO_OYSTERS]),
 ],
 "beignets": [
  ("Cafe Du Monde", "New Orleans", "800", "Beignets and café au lait at the French Market since 1862.", None, None, [NO_BEIGNETS, NO_CLASSIC]),
  ("Cafe Du Monde City Park", "New Orleans", "56", "Café du Monde in City Park.", None, None, [NO_BEIGNETS]),
  ("Cafe Beignet Royal", "New Orleans", "334", "Beignets in a Royal Street courtyard.", None, None, [NO_BEIGNETS]),
  ("Cafe Beignet", "New Orleans", "311", "Café Beignet on Bourbon Street.", None, None, [NO_BEIGNETS]),
  ("Morning Call", "New Orleans", "5101", "Beignets near City Park.", None, None, [NO_BEIGNETS]),
  ("New Orleans Coffee & Beignet Co.", "New Orleans", "700", "Beignets on Tchoupitoulas Street.", None, None, [NO_BEIGNETS]),
  ("The Vintage", "New Orleans", "3121", "Beignets on Magazine Street.", None, None, [NO_BEIGNETS]),
 ],
 "meat pies": [
  ("Lasyone's Meat Pie Restaurant", "Natchitoches", None, "Natchitoches meat pies, served since 1967.", None, None, [NATCH_LASYONE]),
 ],
 "gumbo": [
  ("Herbsaint", "New Orleans", None, "Chef Donald Link's chicken and sausage gumbo; MICHELIN Recommended.", None, None, [NO_26DISH, MI_LA]),
  ("La Boulangerie", "New Orleans", None, "Donald Link's bakery, with his chicken and sausage gumbo.", None, None, [NO_26DISH]),
 ],
 "oldest": [
  ("Mosca's Restaurant", "Westwego", "4137", "A Creole-Italian roadhouse in Avondale; Oysters Mosca. A James Beard America's Classic.", 1946, "Opened in 1946, per the James Beard America's Classics list; the same roadhouse today (New Orleans & Company, May 2026).", [WAC, NO_26DISH]),
 ],
}
ADDR = {}
CUISINE = {("Parkway Bakery & Tavern", "New Orleans"): "Sandwiches & Deli", ("Central Grocery", "New Orleans"): "Sandwiches & Deli",
           ("North Broad Seafood", "New Orleans"): "Seafood"}
KINDS = {"po-boys": ["po-boys"], "creole dining room": ["creole dining room"], "boudin": ["boudin"], "seafood": ["oyster bar"],
         "beignets": ["beignets"], "meat pies": ["meat pies"], "gumbo": ["gumbo"], "oldest": ["oldest"]}

# MICHELIN Guide American South, Louisiana, the 2026 selection (40 places; read through Claude's fetcher, 2026-11-03)
MICHELIN = [("Emeril's", "New Orleans", "2 Stars", "American"), ("Saint-Germain", "New Orleans", "1 Star", "Contemporary"),
            ("Dakar NOLA", "New Orleans", "1 Star", "Senegalese"), ("Zasu", "New Orleans", "1 Star", "Contemporary")] + [
            (n, "New Orleans", "Bib Gourmand", c) for n, c in (("Turkey and the Wolf", "Deli"), ("Acamaya", "Mexican"), ("Mister Mao", "Asian"),
            ("Lufu Nola", "Indian"), ("Dooky Chase", "Creole"), ("Cochon", "Cajun"), ("Saba", "Middle Eastern"), ("Hungry Eyes", "Fusion"),
            ("Safta's Table", "Middle Eastern"), ("Cochon Butcher", "Deli"), ("Domilise's Po-Boy & Bar", "Deli"), ("Parkway Bakery & Tavern", "Deli"))] + [
            (n, t, "Recommended", c) for n, t, c in (("Casimiro", "New Orleans", "Mexican"), ("St. Francisville Inn & Restaurant", "St. Francisville", "American"),
            ("The Kingsway", "New Orleans", "Asian"), ("Pêche", "New Orleans", "Fish and Seafood"), ("Willie Mae's Nola", "New Orleans", "Southern"),
            ("Saffron NOLA", "New Orleans", "Indian"), ("Evviva", "New Orleans", "American"), ("Addis Nola", "New Orleans", "Ethiopian"),
            ("Atchafalaya", "New Orleans", "Southern"), ("Herbsaint", "New Orleans", "Contemporary"), ("Clancy's", "New Orleans", "Creole"),
            ("Restaurant August", "New Orleans", "Contemporary"), ("Jewel of the South", "New Orleans", "Contemporary"),
            ("Feliciana Bistrôt and Bar", "Covington", "Contemporary"), ("Osteria Lupo", "New Orleans", "Italian-American"),
            ("Patois", "New Orleans", "Southern"), ("Galatoire's", "New Orleans", "Creole"), ("La Petite Grocery", "New Orleans", "American"),
            ("The Crustacean Club", "New Orleans", "Seafood"), ("Compère Lapin", "New Orleans", "Caribbean"),
            ("Elsie's Plate & Pie", "Baton Rouge", "American"), ("Killer PoBoys", "New Orleans", "Deli"), ("Saint Claire", "New Orleans", "French"),
            ("Molly's Rise & Shine", "New Orleans", "American"))]
MI_MATCH = {"Dooky Chase": ["DOOKY CHASES RESTAURANT", "DOOKY CHASES"], "Pêche": ["PECHE SEAFOOD GRILL"], "Emeril's": ["EMERILS NEW ORLEANS", "EMERILS RESTAURANT"],
            "Domilise's Po-Boy & Bar": ["DOMILISES", "DOMILISES PO BOYS"], "Killer PoBoys": ["KILLER POBOYS"], "Cochon": ["COCHON RESTAURANT"],
            "Willie Mae's Nola": ["WILLIE MAES NOLA"], "Feliciana Bistrôt and Bar": ["FELICIANA"]}
# James Beard (facts with sources)
JBF = [{"name": "Mosca's Restaurant", "city": "Westwego", "address": "4137 US-90", "honors": ["America's Classic 1999"], "sources": [WAC, NO_26DISH], "match_names": ["MOSCAS RESTAURANT"]},
       {"name": "Hansen's Sno-Bliz", "city": "New Orleans", "address": "4801 Tchoupitoulas St", "honors": ["America's Classic 2014"], "sources": [WAC], "match_names": ["HANSENS SNO BLIZ", "HANSENS"]},
       {"name": "Dong Phuong Bakery", "city": "New Orleans", "address": "14207 Chef Menteur Hwy", "honors": ["America's Classic 2018"], "sources": [WAC], "match_names": ["DONG PHUONG", "DONG PHUONG RESTAURANT AND BAKERY"]},
       {"name": "Dooky Chase's Restaurant", "city": "New Orleans", "address": "2301 Orleans Ave", "honors": ["America's Classic 2025"], "sources": [WAC, NO_CLASSIC], "match_names": ["DOOKY CHASE", "DOOKY CHASES"]},
       {"name": "Dakar NOLA", "city": "New Orleans", "address": "3814 Magazine St", "honors": ["Best Chef: South winner 2026 (Serigne Mbaye)"], "sources": [JBF26, MI_LA]}]
# closed, each with a source
CLOSED = [{"name": "Willie Mae's Scotch House", "city": "New Orleans", "open": False, "match_names": ["WILLIE MAES SCOTCH HOUSE"],
           "note": "Temporarily closed after a fire; Willie Mae's NOLA on Baronne Street is open (New Orleans & Company, April 2026).", "sources": [NO_CLASSIC]}]


def key(s):
    """The name key without a leading "the": "Varsity" is our "The Varsity"."""
    return re.sub(r"^the ", "", norm(s))


def find(name, town, num):
    k = key(name)
    hits = [i for i, n in enumerate(C["name"]) if C["city"][i] is not None and M["cities"][C["city"][i]] == town
            and (key(n) == k or key(n).startswith(k + " ") or k.startswith(key(n) + " ") or key(n).replace(" ", "") == k.replace(" ", "")
                 or (key(n).split()[:2] == k.split()[:2] and len(k.split()) >= 2))]
    if num:
        hits = [i for i in hits if (C["addr"][i] or "").split(" ")[0] == num]
    return hits


leads, n_out = [], {}
for kind, rows in GUIDES.items():
    out = []
    for name, town, num, note, founded, fnote, srcs in rows:
        hits = find(name, town, num)
        if not hits and (name, town) in ADDR:
            out.append({"name": name, "address": ADDR[(name, town)], "city": town, "zip": None, "kinds": KINDS[kind], "dishes": [], "note": note,
                        "founded": founded, "founded_note": fnote, "website": None, "open": True, "evidence_date": "2026-10",
                        "sources": srcs, "match_names": []} | ({"cuisine": CUISINE[(name, town)]} if (name, town) in CUISINE else {}))
            continue
        if len(hits) != 1:
            leads.append(f"- {kind}: {name} ({town}{', ' + num if num else ''}) — {len(hits)} matches in our data; not added"); continue
        i = hits[0]
        out.append({"name": C["name"][i], "address": C["addr"][i], "city": town, "zip": str(C["zip"][i]) if C["zip"][i] else None,
                    "kinds": KINDS[kind], "dishes": [], "note": note, "founded": founded, "founded_note": fnote, "website": None, "open": True,
                    "evidence_date": "2026-10", "sources": srcs, "match_names": [name.upper()] if norm(name) != norm(C["name"][i]) else []})
        if brand_of(norm_name(name)):   # a chain shows under its own spelling at every branch, whatever the listing says
            out[-1]["display"] = name
        if (name, town) in CUISINE:
            out[-1]["cuisine"] = CUISINE[(name, town)]
    fn = re.sub(r"[^a-z]+", "_", kind).strip("_")
    json.dump(out, open(f"{R}/app/{fn}.json", "w"), indent=1, ensure_ascii=False)
    n_out[kind] = len(out)

MI_ADDR = {"Dakar NOLA": "3814 Magazine St"}   # two map listings carry the name; the Magazine Street room is the restaurant
json.dump({"restaurants": [{"name": n, "address": MI_ADDR.get(n), "city": t, "zip": None, "distinction": dist, "cuisine": cu, "green_star": False,
                               "michelin_url": MI_LA, "sources": [MI_LA], "match_names": [x.upper() for x in MI_MATCH.get(n, [])], "open": True}
                              for n, t, dist, cu in MICHELIN]}, open(f"{R}/michelin.json", "w"), indent=1, ensure_ascii=False)
json.dump([dict({"address": None}, **j, zip=None, open=True) for j in JBF], open(f"{R}/jbf.json", "w"), indent=1, ensure_ascii=False)
json.dump(CLOSED, open(f"{R}/closed.json", "w"), indent=1, ensure_ascii=False)
open(f"{R}/app/LEADS.md", "w").write("# Louisiana research leads (not yet verified)\n\nWritten by pipeline/build_research.py.\n\n" + "\n".join(leads) + """

## Waiting for a 2025-26 source we may use
- Sweets: Hansen's Sno-Bliz and Dong Phuong (James Beard America's Classics, so they're honored) and king cake bakeries (Haydel's,
  Manny Randazzo, Sucré) have only 2024-or-older pages; Hansen's and Dong Phuong join the guide once a 2025-26 page names them.
- Muffulettas: Central Grocery's muffuletta, Napoleon House: no 2025-26 page naming the dish found yet (Central Grocery is listed
  under po-boys as a New Orleans classic, April 2026).
- Meat pies: only Lasyone's (the visitors bureau's listing); Cane River Commissary and others need dated pages. The guide shows once
  it has three.
- Gumbo: only Herbsaint and La Boulangerie (May 2026); needs more.
- Oldest: Antoine's (1840, but it moved to St. Louis Street later), Galatoire's (1905), Arnaud's (1918), Commander's Palace (1893),
  Tujague's (moved 2020): no 2025-26 page ties a year to the present address yet.
- Drive-through daiquiri shops: listed as bars (they hold bar permits); Nick's call whether they belong (the prompt asks).
- Blocked or unusable hosts: nola.com, theadvocate.com, nola.eater.com, southernliving.com, gardenandgun.com, wafb.com, fox8live.com
  (robots); louisianatravel.com, ldh.la.gov and dragosrestaurant.com (bot checks).
""")
print(n_out, "| leads:", len(leads))
for l in leads: print(l)
