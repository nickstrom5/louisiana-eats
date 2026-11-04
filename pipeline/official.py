"""Official records for Louisiana -> one table of licensed food and drink businesses (playbook/12-sources.md).

The Louisiana Department of Health (LDH) inspects every parish and grades nothing; its reports sit in a search-only portal
(la.healthinspections.us), never harvested without Nick's yes, and ldh.la.gov answers scripts with a bot check. The statewide alcohol
list (the ATC's) is search-only too. What we can read are the two big cities' open license lists:
- "nola":  New Orleans "Occupational Business Licenses" (data.nola.gov hjcd-grvu, City of New Orleans Bureau of Revenue, updated
           daily): restaurants (full and limited service), drinking places, snack bars, bakeries and cafeterias with a point.
           Owner names are never downloaded.
- "abo":   New Orleans "Alcohol Beverage Outlets" (qfg2-kjjz, CC0, last updated August 2025): outlets permitted to sell alcohol, with
           the outlet's business type; a restaurant, bar or brewery type means drinks served there.
- "ebr":   East Baton Rouge "Businesses Registered with EBR Parish" (data.brla.gov xw6s-bcqm, public domain, updated daily): NAICS
           722000 food services and drinking places, open ("O") or closed ("C"), with a point.
- "ebrabc": East Baton Rouge "ABC_License" (xhjf-mdnv, public domain, August 2026): the parish's alcohol licenses.
Elsewhere a place with no matched record is unknown, never "no". EBR's old LDH violations (ux2t-b9wr, 2020-2025) are history only.

load() returns: jur, lic (our id), name, keys (name keys), addr, city, zip, num, street, lat, lon, kind, active, ltype.
kind: food (a place to eat or drink) | retail (stores, package sales) | other (caterers, trucks, contractors, hotels, events).
"""
import os, re, json, datetime
import numpy as np, pandas as pd
from common import norm_name, RAW, name_sim, _stems, GENERIC, canon_city

OFF = os.path.join(RAW, "official")
DIRS = {"N": "N", "S": "S", "E": "E", "W": "W", "NORTH": "N", "SOUTH": "S", "EAST": "E", "WEST": "W"}
TYPES = set("ST STREET AVE AV AVENUE BLVD BOULEVARD RD ROAD DR DRIVE LN LANE CT COURT PL PLACE PKWY PARKWAY TER TRL TRAIL WAY HWY CIR "
            "CIRCLE PLZ SQ MALL BND PASS XING RUN ROW WALK RDG LOOP FWY FREEWAY EXPY EXPRESSWAY PIKE PK PKE".split())


def road(a):
    """One spelling for numbered roads: 'US HIGHWAY 61' = 'US-61' = 'US 61'; 'LA HIGHWAY 1' = 'LA-1' = 'HWY 1' = 'SH 1';
    'N INTERSTATE 75' = 'I-75'; 'COUNTY ROAD 5' = 'CR 5'."""
    a = re.sub(r"(\d)\s*&\s*(\d)", r"\1-\2", a.upper())
    a = re.sub(r"\b(US|LA|SR|SH|CR|I|IH)-(\w)", r"\1 \2", a)
    a = re.sub(r"\b(?:INTERSTATE(?: HIGHWAY| HWY)?|IH|I H)\s*(?=\d)", "I ", a)
    a = re.sub(r"\b(?:US|U S)\s+(?:HIGHWAY|HWY)\b", "US", a)
    a = re.sub(r"\b(?:FARM[- ]TO[- ]MARKET(?: ROAD| RD)?|FARM (?:ROAD|RD)|F M)\b", "FM", a)
    a = re.sub(r"\b(?:RANCH[- ]TO[- ]MARKET(?: ROAD| RD)?|RANCH (?:ROAD|RD)|RR|RM)\b(?=\s*\d)", "RM", a)
    a = re.sub(r"\b(?:STATE (?:HIGHWAY|HWY|ROAD|RD|ROUTE|RTE)|SR|SH|LOUISIANA (?:HIGHWAY|HWY|STATE (?:HIGHWAY|ROUTE))|LA (?:HIGHWAY|HWY)|LA|HWY)\b(?=\s*\d)", "SH", a)
    a = re.sub(r"\b(?:HISTORIC )?(?:ROUTE|RT|RTE) 66\b", "US 66", a)
    a = re.sub(r"\b(?:COUNTY (?:HIGHWAY|HWY|ROAD|RD)|CO RD|CTY (?:HWY|RD)|CR)\b", "CR", a)
    a = re.sub(r"\bHIGHWAY\b", "HWY", a)
    return re.sub(r"\b(US|SH|CR|HWY|FM|RM|I) (\w+)\s*-\s*\w+", r"\1 \2", a)


ORD = {"FIRST": "1ST", "SECOND": "2ND", "THIRD": "3RD", "FOURTH": "4TH", "FIFTH": "5TH", "SIXTH": "6TH", "SEVENTH": "7TH",
       "EIGHTH": "8TH", "NINTH": "9TH", "TENTH": "10TH", "ELEVENTH": "11TH", "TWELFTH": "12TH"}


def street_key(a):
    """'2505 Monroe St' -> ('2505', 'MONROE'); '1000 OSAGE STREET' -> ('1000', 'OSAGE'); 'E Colfax Ave' keeps 'COLFAX'."""
    if not isinstance(a, str):
        return None, None
    a = re.sub(r"[.,#]", " ", road(a))
    m = re.match(r"^\s*(\d+)[A-Z]?(?:\s*-\s*\d+[A-Z]?)?\s+(.*)$", a)
    if not m:
        return None, None
    words = [w for w in m.group(2).split() if w]
    if len(words) > 1 and words[0] in DIRS:
        words = words[1:]
    core = []
    for w in words:
        if w in TYPES and core:
            break
        core.append(w)
    core = [ORD.get(w, w) for w in core]
    return m.group(1), " ".join(core[:3]) or None


def street_compat(a, b):
    """Same street, or one is a whole-word prefix of the other: Boulder's 2025 set sometimes truncates ("1206 CENTAUR" = Centaur Village Dr)."""
    if not isinstance(a, str) or not isinstance(b, str) or not a or not b:
        return False
    return a == b or a.startswith(b + " ") or b.startswith(a + " ")


def street_nums(a):
    """'157-159 W Main St' -> {'157', '159'}; '2505 Monroe St' -> {'2505'}."""
    if not isinstance(a, str):
        return set()
    a = road(a)
    m = re.match(r"^\s*(\d+)[A-Z]?(?:\s*-\s*(\d+)[A-Z]?)?\s", a.upper() + " ")
    if not m:
        return set()
    lo = int(m.group(1)); hi = int(m.group(2)) if m.group(2) else lo
    if hi < lo:   # "1500-02"
        hi = int(str(lo)[: len(str(lo)) - len(m.group(2))] + m.group(2)) if m.group(2) else lo
    return {str(x) for x in range(lo, hi + 1, 2 if (hi - lo) % 2 == 0 else 1)} if 0 <= hi - lo <= 12 else {str(lo)}


def _names(*vals):
    out = []
    for v in vals:
        if not isinstance(v, str):
            continue
        v = re.sub(r"\s*\((?:MOBILE|MOBILE UNIT|COMMISSARY|CATERING|SPECIAL EVENT|SPEC EVENT|TEMP(?:ORARY)? EVENT|CP|INSIDE [^)]*)\)\s*$", "", v, flags=re.I)
        for part in re.split(r"\s*/\s*|\s+\bdba\b\s+|\s+&\s+(?=[A-Z][a-z])", v, flags=re.I):
            k = norm_name(re.sub(r"\b(?:LLC|INC|CORP|CORPORATION|LTD|CO)\b\.?", "", part, flags=re.I))
            if k and k not in out:
                out.append(k)
    return out





LIST_DATE = None   # set by load(): the dates the city lists were last updated, from their own metadata
META = json.load(open(os.path.join(OFF, "socrata_meta.json")))
NOLA_FILE, ABO_FILE = os.path.join(OFF, "nola", "obl_food.json"), os.path.join(OFF, "nola", "abo.json")
EBR_FILE, EBRABC_FILE = os.path.join(OFF, "ebr", "biz.json"), os.path.join(OFF, "ebr", "abc.json")
NOLA_PAGE = META["hjcd-grvu"]["url"]
INSPECTIONS_URL = "https://la.healthinspections.us/"
NOLA_KIND = {"Full Service Restaurants(table service available)": "food", "Limited Service Restaurants(no table service available)": "food",
             "Drinking Places(Alcoholic Beverages)": "food", "Snack & Nonalcoholic Beverage Bars": "food", "Baked Goods Stores": "food",
             "Cafeterias": "food", "Theater Companies & Dinner Theaters": "other", "Caterers": "other", "Mobile Food Services": "truck",
             "Food Service Contractors": "other", "Community Food Services": "other"}
NOLA_LTYPE = {"Full Service Restaurants(table service available)": "Full-service restaurant", "Limited Service Restaurants(no table service available)": "Limited-service restaurant",
              "Drinking Places(Alcoholic Beverages)": "Drinking place", "Snack & Nonalcoholic Beverage Bars": "Snack or beverage bar",
              "Baked Goods Stores": "Bakery", "Cafeterias": "Cafeteria"}
# alcohol outlets whose business type means drinks are served there
ABO_ONPREM = re.compile(r"Restaurants|Drinking Places|Breweries|Theater|Dinner|Casino|Reception|Amusement|Hotels", re.I)
ONPREM_T = ("New Orleans alcohol outlet (restaurant or bar)", "East Baton Rouge alcohol license")   # only the first says drinks are served


def liq_kind(t):
    """A license type as shown -> on-premises or retail."""
    if not isinstance(t, str):
        return None
    return "onprem" if t in ONPREM_T[:1] else "retail" if t.startswith("New Orleans alcohol outlet (store") else None


def _zip(z):
    z = re.sub(r"\D", "", str(int(z)) if isinstance(z, float) and z == z else str(z or ""))
    return z[:5] if len(z) >= 5 else ""


OTHER = re.compile(r"\b(?:SCHOOL|ELEMENTARY|ACADEMY|HOSPITAL|JAIL|DETENTION|SENIOR|NURSING|FOOD TRUCK|CATERING|CATERER|COMMISSARY|"
                   r"CONCESSION|CHURCH|PARISH|CAMP|CORRECTION(?:AL)?|CAMPUS|WAREHOUSE|COLLEGE|UNIVERSITY|DISTRIBUT\w*|WHOLESALE)\b", re.I)


def _row(jur, lic, name, addr, city, z, la, lo, kind, active=True, ltype=None, holder=None):
    num, st = street_key(addr)
    if kind == "food" and OTHER.search(name or ""):
        kind = "other"
    return {"jur": jur, "lic": lic, "name": name, "dba": name, "holder": holder, "keys": _names(name), "addr": addr, "city": city,
            "zip": _zip(z), "num": num, "street": st, "lat": la, "lon": lo, "kind": kind, "active": active, "ltype": ltype}


def _addr(a):
    """'2790 VETERANS MEMORIAL BLVD STE 130' -> '2790 Veterans Memorial Blvd Ste 130'."""
    a = re.sub(r"\s+", " ", a or "").strip()
    return re.sub(r"\b([A-Z]{2,})\b", lambda m: m.group(1).title(), a)


def _city(c):
    return canon_city(" ".join(w.capitalize() for w in str(c or "").split())) if isinstance(c, str) and c.strip() else None


def _f(x):
    try:
        v = float(x)
        return v if v == v and v != 0 else np.nan
    except (TypeError, ValueError):
        return np.nan


def load_nola():
    rows = []
    for r in json.load(open(NOLA_FILE)):
        bt = r.get("businesstype") or ""
        if bt not in NOLA_KIND:
            continue   # markets, stores and liquor stores aren't places to eat (and the grocery list is only for calibration)
        addr = r.get("address") or " ".join(x for x in (r.get("streetnumber"), r.get("streetdirection"), r.get("streetname"), r.get("streetsuffix")) if x)
        x = _row("nola", f"nola-{r.get('businesslicensenumber')}", re.sub(r"\s+", " ", r.get("businessname") or "").strip(), _addr(addr),
                 _city(r.get("city")) or "New Orleans", r.get("zip"), _f(r.get("latitude")), _f(r.get("longitude")), NOLA_KIND[bt],
                 active=True, ltype=NOLA_LTYPE.get(bt, bt))
        x["issued"] = (r.get("businessstartdate") or "")[:10] or None
        rows.append(x)
    return rows


def load_abo():
    rows = []
    for r in json.load(open(ABO_FILE)):
        bt = re.sub(r"^\d+\s*-\s*", "", r.get("businesstype") or "").strip()
        onprem = bool(ABO_ONPREM.search(bt)) and not re.search(r"Hotels", bt)
        x = _row("abo", f"abo-{r.get('objectid')}", re.sub(r"\s+", " ", r.get("businessname") or "").strip(), _addr(r.get("address")),
                 _city(r.get("city")) or "New Orleans", r.get("zip"), _f(r.get("lat")), _f(r.get("lon")), "food" if onprem else "retail",
                 active=True, ltype=ONPREM_T[0] if onprem else f"New Orleans alcohol outlet (store: {bt})")
        rows.append(x)
    return rows


def load_ebr():
    rows = []
    for r in json.load(open(EBR_FILE)):
        if not str(r.get("tnaic") or "").startswith("722"):
            continue
        g = r.get("geolocation") or {}
        la, lo = (_f(g.get("latitude")), _f(g.get("longitude"))) if isinstance(g, dict) else (np.nan, np.nan)
        if isinstance(g, dict) and g.get("coordinates"):
            lo, la = _f(g["coordinates"][0]), _f(g["coordinates"][1])
        addr = " ".join(x for x in (r.get("tphysicaladdress1"), r.get("tphysicaladdress2")) if x)
        x = _row("ebr", f"ebr-{r.get('taccount')}", re.sub(r"\s+", " ", r.get("tname") or "").strip(), _addr(addr), _city(r.get("tphysicalcity")),
                 r.get("tphysicalzipcode5"), la, lo, "food", active=(r.get("tstatus") == "O"), ltype="East Baton Rouge business registration")
        x["issued"] = (r.get("topendate") or "")[:10] or None
        rows.append(x)
    return rows


def load_ebrabc():
    rows = []
    for r in json.load(open(EBRABC_FILE)):
        g = r.get("the_geom") or {}
        lo, la = (_f(g["coordinates"][0]), _f(g["coordinates"][1])) if isinstance(g, dict) and g.get("coordinates") else (np.nan, np.nan)
        x = _row("ebrabc", f"ebrabc-{r.get('rev_acct_num') or r.get('objectid')}", re.sub(r"\s+", " ", r.get("account_name") or "").strip(),
                 _addr(r.get("address")), _city(r.get("city")), r.get("zip"), la, lo, "retail", active=True, ltype=ONPREM_T[1])
        # "retail": the list doesn't say package or on-premises, so it confirms a place but never adds one or says "serves alcohol"
        rows.append(x)
    return rows


def load():
    global LIST_DATE
    LIST_DATE = META["hjcd-grvu"]["rows_updated"]
    df = pd.DataFrame(load_nola() + load_abo() + load_ebr() + load_ebrabc())
    # one business can hold several records (a business license and an alcohol outlet at one address under one name)
    df["biz"] = np.arange(len(df))
    town = df.city.fillna("").str.upper().str.strip()
    for num, g in df[df.num.notna() & df.street.notna()].groupby("num"):
        idx = list(g.index)
        if len(idx) < 2 or len(idx) > 400:
            continue
        for x in range(len(idx)):
            for y in range(x + 1, len(idx)):
                a, b = idx[x], idx[y]
                if not street_compat(df.at[a, "street"], df.at[b, "street"]):
                    continue
                if not ((df.at[a, "zip"] and df.at[a, "zip"] == df.at[b, "zip"]) or (town[a] and town[a] == town[b])):
                    continue
                ka, kb = df.at[a, "keys"], df.at[b, "keys"]
                if not ka or not kb:
                    continue
                if any(name_sim(p, q) >= 85 or ((_stems(p) - GENERIC) & (_stems(q) - GENERIC)) for p in ka for q in kb):
                    old, new = df.at[b, "biz"], df.at[a, "biz"]
                    df.loc[df.biz == old, "biz"] = new
    df["county"] = None   # the parish, set from the point (geocode_official.py, calibrate.py)
    return df
