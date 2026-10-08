"""Pull college data for matching.

IPEDS complete data files come from the NCES Data Center. Common Data Set
figures come from the public collegedata.fyi extract (MIT-licensed), which
is keyed by the same IPEDS UNITID. There is no official bulk CDS download;
colleges publish those reports one school at a time.

Run from the repo root:

    python3 scripts/pull_colleges.py

Raw zips land in data/raw/ and are not committed. Matching tables land in data/.
"""

import csv
import hashlib
import io
import json
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path

from majors import MAJORS

# Women's College Coalition members that are separate IPEDS institutions.
# Douglass Residential College is part of Rutgers and has no UNITID of its own.
WOMENS_COLLEGES = {
    "138600",  # Agnes Scott College
    "238193",  # Alverno College
    "189097",  # Barnard College
    "164632",  # Bay Path University
    "197993",  # Bennett College
    "139199",  # Brenau University
    "211273",  # Bryn Mawr College
    "211468",  # Cedar Crest College
    "174747",  # College of Saint Benedict
    "181604",  # College of Saint Mary
    "217961",  # Converse University
    "177117",  # Cottey College
    "232308",  # Hollins University
    "198950",  # Meredith College
    "176035",  # Mississippi University for Women
    "214148",  # Moore College of Art and Design
    "166939",  # Mount Holyoke College
    "239390",  # Mount Mary University
    "119173",  # Mount Saint Mary's University (California)
    "152390",  # Saint Mary's College (Indiana)
    "199607",  # Salem College
    "123165",  # Scripps College
    "167783",  # Simmons University
    "167835",  # Smith College
    "141060",  # Spelman College
    "175005",  # St. Catherine University
    "179548",  # Stephens College
    "229179",  # Texas Woman's University
    "131876",  # Trinity Washington University
    "168218",  # Wellesley College
    "141325",  # Wesleyan College (Georgia)
}

SCORECARD = {
    "scorecard_institution.zip": "https://ed-public-download.scorecard.network/downloads/Most-Recent-Cohorts-Institution_06102026.zip",
    "scorecard_field.zip": "https://ed-public-download.scorecard.network/downloads/Most-Recent-Cohorts-Field-of-Study_06102026.zip",
}
ZCTA_URL = "https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2025_Gazetteer/2025_Gaz_zcta_national.zip"

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
OUT = ROOT / "data"

IPEDS = {
    "HD2024.zip": "https://nces.ed.gov/ipeds/datacenter/data/HD2024.zip",
    "IC2023.zip": "https://nces.ed.gov/ipeds/datacenter/data/IC2023.zip",
    "IC2023_AY.zip": "https://nces.ed.gov/ipeds/datacenter/data/IC2023_AY.zip",
    "ADM2023.zip": "https://nces.ed.gov/ipeds/datacenter/data/ADM2023.zip",
    "EF2023A.zip": "https://nces.ed.gov/ipeds/datacenter/data/EF2023A.zip",
    "SFA2223.zip": "https://nces.ed.gov/ipeds/datacenter/data/SFA2223.zip",
    "DRVGR2023.zip": "https://nces.ed.gov/ipeds/datacenter/data/DRVGR2023.zip",
    "C2023_A.zip": "https://nces.ed.gov/ipeds/datacenter/data/C2023_A.zip",
}

# Public read-only key published by collegedata.fyi for their API.
CDS_KEY = (
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9."
    "eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlzZHV3bXlndm1kb3pocHZ6YWl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxMDk3NTksImV4cCI6MjA5MTY4NTc1OX0."
    "fYZOIHyrOWzidgc-CVxWCY5Fe9pQk12-6YjDIS6y9qs"
)
CDS_API = "https://api.collegedata.fyi/rest/v1"

STATES = {
    "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA",
    "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA",
    "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY",
    "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX",
    "UT", "VT", "VA", "WA", "WV", "WI", "WY",
}

REGIONS = {
    "1": "Northeast", "2": "Northeast",
    "3": "Midwest", "4": "Midwest",
    "5": "South", "6": "South",
    "7": "West", "8": "West",
}

# Service academies are coded outside the census regions, so fall back to state.
STATE_REGIONS = {
    "CT": "Northeast", "ME": "Northeast", "MA": "Northeast", "NH": "Northeast",
    "RI": "Northeast", "VT": "Northeast", "NJ": "Northeast", "NY": "Northeast",
    "PA": "Northeast",
    "IL": "Midwest", "IN": "Midwest", "MI": "Midwest", "OH": "Midwest",
    "WI": "Midwest", "IA": "Midwest", "KS": "Midwest", "MN": "Midwest",
    "MO": "Midwest", "NE": "Midwest", "ND": "Midwest", "SD": "Midwest",
    "DE": "South", "DC": "South", "FL": "South", "GA": "South", "MD": "South",
    "NC": "South", "SC": "South", "VA": "South", "WV": "South", "AL": "South",
    "KY": "South", "MS": "South", "TN": "South", "AR": "South", "LA": "South",
    "OK": "South", "TX": "South",
    "AZ": "West", "CO": "West", "ID": "West", "MT": "West", "NV": "West",
    "NM": "West", "UT": "West", "WY": "West", "AK": "West", "CA": "West",
    "HI": "West", "OR": "West", "WA": "West",
}

LOCALES = {
    "11": ("city_large", "urban"),
    "12": ("city_midsize", "urban"),
    "13": ("city_small", "urban"),
    "21": ("suburb_large", "suburban"),
    "22": ("suburb_midsize", "suburban"),
    "23": ("suburb_small", "suburban"),
    "31": ("town_fringe", "town"),
    "32": ("town_distant", "town"),
    "33": ("town_remote", "town"),
    "41": ("rural_fringe", "rural"),
    "42": ("rural_distant", "rural"),
    "43": ("rural_remote", "rural"),
}

CONTROLS = {"1": "public", "2": "private_nonprofit", "3": "private_forprofit"}

# IPEDS ADMCON codes, 2023-24 admissions component.
CONSIDERED = {
    "1": "required",
    "5": "considered_if_submitted",
    "3": "not_considered",
}
TEST_POLICY = {
    "1": "required",
    "5": "test_optional",
    "3": "test_blind",
}

CIP2 = {
    "01": "Agriculture",
    "03": "Natural resources",
    "04": "Architecture",
    "05": "Area, ethnic, and cultural studies",
    "09": "Communication and journalism",
    "10": "Communications technologies",
    "11": "Computer and information sciences",
    "13": "Education",
    "14": "Engineering",
    "15": "Engineering technologies",
    "16": "Foreign languages and linguistics",
    "19": "Family and consumer sciences",
    "22": "Legal professions",
    "23": "English language and literature",
    "24": "Liberal arts and humanities",
    "26": "Biological sciences",
    "27": "Mathematics and statistics",
    "30": "Interdisciplinary studies",
    "31": "Parks, recreation, and fitness",
    "38": "Philosophy and religious studies",
    "39": "Theology",
    "40": "Physical sciences",
    "41": "Science technologies",
    "42": "Psychology",
    "43": "Homeland security and law enforcement",
    "44": "Public administration",
    "45": "Social sciences",
    "50": "Visual and performing arts",
    "51": "Health professions",
    "52": "Business",
    "54": "History",
}

GPA_FIELDS = {
    "C.1121": "4.0",
    "C.1122": "3.75_3.99",
    "C.1123": "3.50_3.74",
    "C.1124": "3.25_3.49",
    "C.1125": "3.00_3.24",
    "C.1126": "2.50_2.99",
    "C.1127": "2.00_2.49",
    "C.1128": "1.00_1.99",
    "C.1129": "below_1.0",
}

BROWSER_COLUMNS = ",".join([
    "ipeds_id", "school_id", "school_name", "canonical_year",
    "applied", "admitted", "acceptance_rate", "yield_rate", "enrolled_first_year",
    "sat_submit_rate", "act_submit_rate",
    "sat_ebrw_p25", "sat_ebrw_p50", "sat_ebrw_p75",
    "sat_math_p25", "sat_math_p50", "sat_math_p75",
    "sat_composite_p25", "sat_composite_p50", "sat_composite_p75",
    "act_composite_p25", "act_composite_p50", "act_composite_p75",
    "ed_offered", "ed_applicants", "ed_admitted", "ea_offered", "ea_restrictive",
    "archive_url", "data_quality_flag",
])


def download(name: str, url: str) -> Path:
    RAW.mkdir(parents=True, exist_ok=True)
    dest = RAW / name
    if dest.exists() and dest.stat().st_size > 0:
        return dest
    print(f"downloading {name}")
    request = urllib.request.Request(url, headers={"User-Agent": "Jaccepted/0.1"})
    with urllib.request.urlopen(request, timeout=180) as response:
        dest.write_bytes(response.read())
    return dest


def iter_csv(zip_path: Path, prefer: str | None = None):
    with zipfile.ZipFile(zip_path) as archive:
        names = [name for name in archive.namelist() if name.lower().endswith(".csv")]
        member = names[0]
        if prefer:
            revised = [name for name in names if name.lower() == prefer.lower()]
            if revised:
                member = revised[0]
        with archive.open(member) as handle:
            text = io.TextIOWrapper(handle, encoding="utf-8-sig", newline="")
            for row in csv.DictReader(text):
                yield {
                    (key or "").strip(): value.strip() if isinstance(value, str) else value
                    for key, value in row.items()
                }


def num(value: str | None) -> float | None:
    if value is None:
        return None
    text = value.strip()
    if text in {"", ".", "-"}:
        return None
    try:
        number = float(text)
    except ValueError:
        return None
    if number < 0:
        return None
    return number


def signed_num(value: str | None) -> float | None:
    if value is None:
        return None
    text = value.strip()
    if text in {"", ".", "-"}:
        return None
    try:
        return float(text)
    except ValueError:
        return None


def whole(value: str | None) -> int | None:
    number = num(value)
    if number is None:
        return None
    return int(number)


def ratio(part: float | None, whole_value: float | None) -> float | None:
    if part is None or whole_value is None or whole_value <= 0:
        return None
    return round(part / whole_value, 6)


def percent_rate(value: str | None) -> float | None:
    number = num(value)
    if number is None:
        return None
    return round(number / 100, 6)


def money(value: str | None) -> int | None:
    number = num(value)
    if number is None:
        return None
    return int(number)


def add_money(left: int | None, right: int | None) -> int | None:
    if left is None or right is None:
        return None
    return left + right


def size_band(enrollment: int | None) -> str | None:
    if enrollment is None:
        return None
    if enrollment < 5000:
        return "small"
    if enrollment <= 15000:
        return "medium"
    return "large"


def index_by_unit(rows, columns: list[str]) -> dict[str, dict]:
    indexed = {}
    for row in rows:
        unit = row.get("UNITID", "")
        if unit:
            indexed[unit] = {column: row.get(column, "") for column in columns}
    return indexed


def load_ipeds() -> tuple[list[dict], list[dict]]:
    for name, url in IPEDS.items():
        download(name, url)

    directory = index_by_unit(iter_csv(RAW / "HD2024.zip"), [
        "INSTNM", "CITY", "STABBR", "SECTOR", "CONTROL", "DEGGRANT", "CYACTIVE",
        "HBCU", "TRIBAL", "LOCALE", "OBEREG", "LATITUDE", "LONGITUD", "WEBADDR", "OPEID",
    ])
    characteristics = index_by_unit(
        iter_csv(RAW / "IC2023.zip", prefer="IC2023_RV.csv"),
        ["RELAFFIL", "OPENADMP", "ROOMAMT", "BOARDAMT", "RMBRDAMT", "APPLFEEU"],
    )
    charges = index_by_unit(iter_csv(RAW / "IC2023_AY.zip"), [
        "TUITION2", "FEE2", "TUITION3", "FEE3",
    ])
    admissions = index_by_unit(iter_csv(RAW / "ADM2023.zip"), [
        "ADMCON1", "ADMCON7", "APPLCN", "ADMSSN", "ENRLT",
        "SATVR25", "SATVR75", "SATMT25", "SATMT75",
        "ACTCM25", "ACTCM75", "SATPCT", "ACTPCT",
    ])
    aid = index_by_unit(iter_csv(RAW / "SFA2223.zip"), [
        "NPIST2",
        "NPIS412", "NPIS422", "NPIS432", "NPIS442", "NPIS452",
        "NPT412", "NPT422", "NPT432", "NPT442", "NPT452",
    ])
    graduation = index_by_unit(iter_csv(RAW / "DRVGR2023.zip"), ["GBA4RTT", "GBA6RTT"])

    enrollment = {}
    for row in iter_csv(RAW / "EF2023A.zip"):
        if row.get("EFALEVEL") == "2":
            enrollment[row["UNITID"]] = whole(row.get("EFTOTLT"))

    programs: dict[tuple[str, str], int] = {}
    for row in iter_csv(RAW / "C2023_A.zip", prefer="C2023_a_RV.csv"):
        if row.get("AWLEVEL") != "5":
            continue
        cip = row.get("CIPCODE", "")
        if cip in {"", "99", "99.0000"}:
            continue
        awards = whole(row.get("CTOTALT"))
        if not awards:
            continue
        key = (row["UNITID"], cip)
        programs[key] = programs.get(key, 0) + awards

    colleges = []
    for unit, school in directory.items():
        if school["STABBR"] not in STATES:
            continue
        if school["SECTOR"] not in {"1", "2", "3"}:
            continue
        if school["DEGGRANT"] != "1" or school["CYACTIVE"] != "1":
            continue
        info = characteristics.get(unit, {})
        price = charges.get(unit, {})
        admit = admissions.get(unit, {})
        costs = aid.get(unit, {})
        grads = graduation.get(unit, {})
        applicants = whole(admit.get("APPLCN"))
        admitted = whole(admit.get("ADMSSN"))
        enrolled = whole(admit.get("ENRLT"))
        undergrad = enrollment.get(unit)
        locale, setting = LOCALES.get(school["LOCALE"], (None, None))
        room_board = money(info.get("RMBRDAMT"))
        if room_board is None:
            room_board = add_money(money(info.get("ROOMAMT")), money(info.get("BOARDAMT")))
        public = school["CONTROL"] == "1"
        band_prefix = "NPIS" if public else "NPT"
        bands = {
            "0_30": money(costs.get(f"{band_prefix}412")),
            "30_48": money(costs.get(f"{band_prefix}422")),
            "48_75": money(costs.get(f"{band_prefix}432")),
            "75_110": money(costs.get(f"{band_prefix}442")),
            "110_plus": money(costs.get(f"{band_prefix}452")),
        }
        if all(value is None for value in bands.values()):
            other = "NPT" if public else "NPIS"
            bands = {
                "0_30": money(costs.get(f"{other}412")),
                "30_48": money(costs.get(f"{other}422")),
                "48_75": money(costs.get(f"{other}432")),
                "75_110": money(costs.get(f"{other}442")),
                "110_plus": money(costs.get(f"{other}452")),
            }
        affiliation = whole(info.get("RELAFFIL"))
        colleges.append({
            "unitid": unit,
            "opeid": school["OPEID"] or None,
            "name": school["INSTNM"],
            "city": school["CITY"],
            "state": school["STABBR"],
            "region": REGIONS.get(school["OBEREG"]) or STATE_REGIONS.get(school["STABBR"]),
            "locale": locale,
            "setting": setting,
            "control": CONTROLS.get(school["CONTROL"]),
            "hbcu": school["HBCU"] == "1",
            "tribal_college": school["TRIBAL"] == "1",
            "religiously_affiliated": affiliation is not None and affiliation > 0,
            "open_admission": info.get("OPENADMP") == "1",
            "latitude": signed_num(school["LATITUDE"]),
            "longitude": signed_num(school["LONGITUD"]),
            "website": school["WEBADDR"] or None,
            "undergrad_enrollment": undergrad,
            "size_band": size_band(undergrad),
            "applicants": applicants,
            "admitted": admitted,
            "enrolled": enrolled,
            "admit_rate": ratio(admitted, applicants),
            "yield_rate": ratio(enrolled, admitted),
            "sat_reading_p25": whole(admit.get("SATVR25")),
            "sat_reading_p75": whole(admit.get("SATVR75")),
            "sat_math_p25": whole(admit.get("SATMT25")),
            "sat_math_p75": whole(admit.get("SATMT75")),
            "act_p25": whole(admit.get("ACTCM25")),
            "act_p75": whole(admit.get("ACTCM75")),
            "sat_submit_rate": percent_rate(admit.get("SATPCT")),
            "act_submit_rate": percent_rate(admit.get("ACTPCT")),
            "gpa_policy": CONSIDERED.get(admit.get("ADMCON1", "")),
            "test_policy": TEST_POLICY.get(admit.get("ADMCON7", "")),
            "tuition_in_state": money(price.get("TUITION2")),
            "fees_in_state": money(price.get("FEE2")),
            "tuition_out_of_state": money(price.get("TUITION3")),
            "fees_out_of_state": money(price.get("FEE3")),
            "room_and_board": room_board,
            "application_fee": money(info.get("APPLFEEU")),
            "net_price": money(costs.get("NPIST2")),
            "net_price_0_30k": bands["0_30"],
            "net_price_30_48k": bands["30_48"],
            "net_price_48_75k": bands["48_75"],
            "net_price_75_110k": bands["75_110"],
            "net_price_110k_plus": bands["110_plus"],
            "grad_rate_4yr": percent_rate(grads.get("GBA4RTT")),
            "grad_rate_6yr": percent_rate(grads.get("GBA6RTT")),
            "womens_college": unit in WOMENS_COLLEGES,
            "earnings_6yr": None,
            "earnings_10yr": None,
            "median_debt": None,
            "pell_share": None,
            "retention_rate": None,
            "first_gen_share": None,
            "bachelor_program_count": 0,
        })

    program_rows = []
    counts: dict[str, int] = {}
    college_ids = {college["unitid"] for college in colleges}
    for (unit, cip), awards in programs.items():
        if unit not in college_ids:
            continue
        cip2 = cip.split(".")[0].zfill(2)[:2]
        program_rows.append({
            "unitid": unit,
            "cip": cip,
            "cip_family": CIP2.get(cip2),
            "bachelor_awards": awards,
            "earnings_1yr": None,
        })
        counts[unit] = counts.get(unit, 0) + 1
    for college in colleges:
        college["bachelor_program_count"] = counts.get(college["unitid"], 0)
    colleges.sort(key=lambda college: (college["name"], college["unitid"]))
    program_rows.sort(key=lambda program: (program["unitid"], program["cip"]))
    return colleges, program_rows


def cds_get(path: str, params: dict[str, str]) -> list[dict]:
    query = urllib.parse.urlencode(params)
    url = f"{CDS_API}/{path}?{query}"
    cache = RAW / "cds-cache" / f"{hashlib.sha256(url.encode()).hexdigest()}.json"
    if cache.exists():
        return json.loads(cache.read_text(encoding="utf-8"))
    request = urllib.request.Request(
        url,
        headers={
            "apikey": CDS_KEY,
            "Authorization": f"Bearer {CDS_KEY}",
            "Accept": "application/json",
            "User-Agent": "Jaccepted/0.1",
        },
    )
    delay = 2
    last_error = "unknown error"
    for _attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=90) as response:
                body = response.read().decode("utf-8")
            break
        except urllib.error.HTTPError as error:
            last_error = error.read().decode("utf-8", errors="replace")
            if "57014" not in last_error:
                raise RuntimeError(f"CDS {path} failed ({error.code}): {last_error}") from error
            time.sleep(delay)
            delay *= 2
    else:
        raise RuntimeError(f"CDS {path} timed out: {last_error}")
    payload = json.loads(body)
    if not isinstance(payload, list):
        raise RuntimeError(f"CDS {path} returned {payload}")
    cache.parent.mkdir(parents=True, exist_ok=True)
    cache.write_text(body, encoding="utf-8")
    return payload


def cds_pages(path: str, params: dict[str, str]) -> list[dict]:
    rows = []
    offset = 0
    while True:
        page = cds_get(path, {**params, "limit": "1000", "offset": str(offset)})
        rows.extend(page)
        if len(page) < 1000:
            return rows
        offset += 1000


def newer(year: str | None, candidate: str | None) -> bool:
    if not candidate:
        return False
    if not year:
        return True
    return candidate > year


def published(row: dict):
    text = row.get("value_text")
    if text not in (None, ""):
        try:
            return float(text)
        except (TypeError, ValueError):
            return text.strip()
    return row.get("value_num")


def load_cds() -> list[dict]:
    browser = []
    for year in ("2024-25", "2025-26"):
        browser.extend(cds_pages("school_browser_rows", {
            "select": BROWSER_COLUMNS,
            "canonical_year": f"eq.{year}",
            "order": "ipeds_id.asc",
        }))
    schools: dict[str, dict] = {}
    for row in browser:
        if not row.get("ipeds_id"):
            continue
        unit = str(row["ipeds_id"]).zfill(6)
        current = schools.get(unit)
        if current and not newer(current["cds_year"], row.get("canonical_year")):
            continue
        admitted = row.get("ed_admitted")
        applicants = row.get("ed_applicants")
        schools[unit] = {
            "unitid": unit,
            "school_id": row.get("school_id"),
            "name": row.get("school_name"),
            "cds_year": row.get("canonical_year"),
            "source": "https://www.collegedata.fyi",
            "archive_url": row.get("archive_url"),
            "data_quality_flag": row.get("data_quality_flag"),
            "applied": row.get("applied"),
            "admitted": row.get("admitted"),
            "admit_rate": row.get("acceptance_rate"),
            "yield_rate": row.get("yield_rate"),
            "enrolled": row.get("enrolled_first_year"),
            "sat_submit_rate": row.get("sat_submit_rate"),
            "act_submit_rate": row.get("act_submit_rate"),
            "sat_reading_p25": row.get("sat_ebrw_p25"),
            "sat_reading_p50": row.get("sat_ebrw_p50"),
            "sat_reading_p75": row.get("sat_ebrw_p75"),
            "sat_math_p25": row.get("sat_math_p25"),
            "sat_math_p50": row.get("sat_math_p50"),
            "sat_math_p75": row.get("sat_math_p75"),
            "sat_composite_p25": row.get("sat_composite_p25"),
            "sat_composite_p50": row.get("sat_composite_p50"),
            "sat_composite_p75": row.get("sat_composite_p75"),
            "act_p25": row.get("act_composite_p25"),
            "act_p50": row.get("act_composite_p50"),
            "act_p75": row.get("act_composite_p75"),
            "ed_offered": row.get("ed_offered"),
            "ed_applicants": applicants,
            "ed_admitted": admitted,
            "ed_admit_rate": ratio(admitted, applicants),
            "ea_offered": row.get("ea_offered"),
            "ea_restrictive": row.get("ea_restrictive"),
            "in_state_applied": None,
            "in_state_admitted": None,
            "in_state_admit_rate": None,
            "out_of_state_applied": None,
            "out_of_state_admitted": None,
            "out_of_state_admit_rate": None,
            "gpa_average": None,
            "gpa_submit_rate": None,
            "gpa_pct": {},
            "uses_test_scores": None,
            "test_policy": None,
            "gpa_importance": None,
            "test_importance": None,
        }

    field_ids = {
        **GPA_FIELDS,
        "C.1201": "gpa_average",
        "C.1202": "gpa_submit",
        "C.801": "uses_tests",
        "C.802": "test_policy",
        "C.703": "gpa_importance",
        "C.704": "test_importance",
        "C.120": "in_state_applied",
        "C.121": "in_state_admitted",
        "C.123": "out_of_state_applied",
        "C.124": "out_of_state_admitted",
    }
    latest: dict[tuple[str, str], tuple[str, dict]] = {}
    for field_id in field_ids:
        print(f"cds field {field_id}")
        rows = []
        for year in ("2024-25", "2025-26"):
            rows.extend(cds_pages("cds_fields", {
                "select": "ipeds_id,canonical_year,value_num,value_text",
                "field_id": f"eq.{field_id}",
                "canonical_year": f"eq.{year}",
            }))
        for row in rows:
            if not row.get("ipeds_id"):
                continue
            unit = str(row["ipeds_id"]).zfill(6)
            year = row.get("canonical_year") or ""
            key = (unit, field_id)
            previous = latest.get(key)
            if previous and previous[0] >= year:
                continue
            latest[key] = (year, row)

    for (unit, field_id), (_year, row) in latest.items():
        school = schools.setdefault(unit, {
            "unitid": unit,
            "school_id": None,
            "name": None,
            "cds_year": _year,
            "source": "https://www.collegedata.fyi",
            "archive_url": None,
            "data_quality_flag": None,
            "gpa_pct": {},
        })
        value = published(row)
        if field_id in GPA_FIELDS:
            if isinstance(value, float):
                school.setdefault("gpa_pct", {})[GPA_FIELDS[field_id]] = value
            continue
        target = field_ids[field_id]
        if target == "gpa_average":
            school["gpa_average"] = value if isinstance(value, float) else None
        elif target == "gpa_submit":
            school["gpa_submit_rate"] = round(value / 100, 6) if isinstance(value, float) else None
        elif target == "uses_tests":
            school["uses_test_scores"] = row.get("value_text") or None
        elif target in {"test_policy", "gpa_importance", "test_importance"}:
            school[target] = row.get("value_text") or None
        elif target in {"in_state_applied", "in_state_admitted", "out_of_state_applied", "out_of_state_admitted"}:
            school[target] = int(value) if isinstance(value, float) else None

    for school in schools.values():
        school["in_state_admit_rate"] = ratio(school.get("in_state_admitted"), school.get("in_state_applied"))
        school["out_of_state_admit_rate"] = ratio(
            school.get("out_of_state_admitted"), school.get("out_of_state_applied")
        )
        school.setdefault("gpa_pct", {})
    records = [school for school in schools.values() if school.get("unitid")]
    records.sort(key=lambda school: (school.get("name") or "", school["unitid"]))
    return records


def scorecard_number(value: str | None) -> float | None:
    if value is None:
        return None
    text = value.strip()
    if text in {"", "NULL", "NA", "PS", "PrivacySuppressed"}:
        return None
    return num(text)


def fraction(value: str | None) -> float | None:
    number = scorecard_number(value)
    if number is None:
        return None
    if number > 1:
        number = number / 100
    return round(number, 6)


def cip4(cip: str) -> str:
    digits = "".join(character for character in cip if character.isdigit())
    return digits[:4]


def money_from(value: str | None) -> int | None:
    number = scorecard_number(value)
    if number is None:
        return None
    return int(number)


def iter_scorecard(zip_name: str, member: str):
    with zipfile.ZipFile(RAW / zip_name) as archive:
        with archive.open(member) as handle:
            text = io.TextIOWrapper(handle, encoding="utf-8", newline="")
            yield from csv.DictReader(text)


def attach_scorecard(colleges: list[dict], programs: list[dict]) -> None:
    for name, url in SCORECARD.items():
        download(name, url)
    by_id = {college["unitid"]: college for college in colleges}
    for row in iter_scorecard("scorecard_institution.zip", "Most-Recent-Cohorts-Institution.csv"):
        college = by_id.get(row.get("UNITID", ""))
        if college is None:
            continue
        college["earnings_6yr"] = money_from(row.get("MD_EARN_WNE_P6"))
        college["earnings_10yr"] = money_from(row.get("MD_EARN_WNE_P10"))
        college["median_debt"] = money_from(row.get("DEBT_MDN"))
        college["pell_share"] = fraction(row.get("PCTPELL"))
        college["retention_rate"] = fraction(row.get("RET_FT4"))
        college["first_gen_share"] = fraction(row.get("FIRST_GEN"))
    earnings = {}
    for row in iter_scorecard("scorecard_field.zip", "Most-Recent-Cohorts-Field-of-Study.csv"):
        if row.get("CREDLEV") != "3":
            continue
        amount = money_from(row.get("EARN_MDN_1YR"))
        if amount is None:
            continue
        earnings[(row.get("UNITID", ""), cip4(row.get("CIPCODE", "")))] = amount
    for program in programs:
        program["earnings_1yr"] = earnings.get((program["unitid"], cip4(program["cip"])))


def write_majors() -> None:
    payload = [{"name": name, "cip_prefixes": prefixes} for name, prefixes in MAJORS]
    (OUT / "majors.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    lines = [
        '"""Suggested majors for the intake form.',
        "",
        "Written by scripts/pull_colleges.py from scripts/majors.py.",
        '"""',
        "",
        "glob MAJOR_NAMES: list[str] = [",
    ]
    for name, _prefixes in MAJORS:
        escaped = name.replace("\\", "\\\\").replace('"', '\\"')
        lines.append(f'    "{escaped}",')
    lines.append("];")
    lines.append("")
    (ROOT / "majors.jac").write_text("\n".join(lines), encoding="utf-8")


def write_zip_centroids() -> int:
    download("zcta2025.zip", ZCTA_URL)
    rows = []
    with zipfile.ZipFile(RAW / "zcta2025.zip") as archive:
        member = next(name for name in archive.namelist() if name.endswith(".txt"))
        with archive.open(member) as handle:
            text = io.TextIOWrapper(handle, encoding="utf-8-sig", newline="")
            for row in csv.DictReader(text, delimiter="|"):
                code = (row.get("GEOID") or "").strip().zfill(5)
                latitude = signed_num(row.get("INTPTLAT"))
                longitude = signed_num(row.get("INTPTLONG"))
                if len(code) != 5 or latitude is None or longitude is None:
                    continue
                rows.append({"zip": code, "latitude": latitude, "longitude": longitude})
    rows.sort(key=lambda item: item["zip"])
    cambridge = next(row for row in rows if row["zip"] == "02138")
    if not (42.3 < cambridge["latitude"] < 42.5 and -71.2 < cambridge["longitude"] < -71.0):
        raise SystemExit(f"Cambridge ZIP centroid looks wrong: {cambridge}")
    if len(rows) < 30000:
        raise SystemExit(f"Expected tens of thousands of ZIP centroids, got {len(rows)}")
    write_jsonl(OUT / "zip_centroids.jsonl", rows)
    return len(rows)


def write_jsonl(path: Path, rows: list[dict]) -> None:
    with path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")


def check(colleges: list[dict], programs: list[dict], cds: list[dict]) -> None:
    by_id = {college["unitid"]: college for college in colleges}
    harvard = by_id["166027"]
    michigan = by_id["170976"]
    texas = by_id["228778"]
    florida = by_id["134130"]
    if not (0.01 < harvard["admit_rate"] < 0.10):
        raise SystemExit(f"Harvard admit rate looks wrong: {harvard['admit_rate']}")
    if not (michigan["tuition_in_state"] < michigan["tuition_out_of_state"]):
        raise SystemExit("Michigan in-state tuition should be below out-of-state")
    if texas["region"] != "South" or texas["state"] != "TX":
        raise SystemExit("UT Austin region was not mapped to the South")
    if florida["test_policy"] != "required" or harvard["test_policy"] != "test_optional":
        raise SystemExit("Test-policy labels do not match known schools")
    if harvard["net_price_0_30k"] is None or michigan["net_price_0_30k"] is None:
        raise SystemExit("Net price by income is missing for Harvard or Michigan")
    harvard_programs = [row for row in programs if row["unitid"] == "166027"]
    if not any(row["cip"].startswith("11.") for row in harvard_programs):
        raise SystemExit("Harvard is missing computer-science bachelor's awards")
    cds_ids = {row["unitid"] for row in cds}
    if "166027" not in cds_ids:
        raise SystemExit("Harvard is missing from the Common Data Set extract")
    if harvard["earnings_10yr"] is None or harvard["earnings_10yr"] < 50000:
        raise SystemExit(f"Harvard 10-year earnings look wrong: {harvard['earnings_10yr']}")
    if harvard["womens_college"] or not by_id["168218"]["womens_college"] or not by_id["167835"]["womens_college"]:
        raise SystemExit("Women's college flags are wrong for Harvard, Wellesley, or Smith")
    computer_science = next(row for row in harvard_programs if row["cip"] == "11.0701")
    if computer_science["earnings_1yr"] is None or abs(computer_science["earnings_1yr"] - 152251) > 1:
        raise SystemExit(f"Harvard computer science earnings look wrong: {computer_science['earnings_1yr']}")
    if sum(1 for college in colleges if college["womens_college"]) != 31:
        raise SystemExit("Expected 31 women's colleges")
    if harvard["longitude"] is None or harvard["longitude"] > -70:
        raise SystemExit(f"Harvard longitude looks wrong: {harvard['longitude']}")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    colleges, programs = load_ipeds()
    attach_scorecard(colleges, programs)
    cds = load_cds()
    check(colleges, programs, cds)
    write_jsonl(OUT / "colleges.jsonl", colleges)
    write_jsonl(OUT / "programs.jsonl", programs)
    write_jsonl(OUT / "cds.jsonl", cds)
    write_majors()
    zip_count = write_zip_centroids()
    with_admit = sum(1 for college in colleges if college["admit_rate"] is not None)
    with_scores = sum(1 for college in colleges if college["sat_reading_p25"] is not None)
    with_price = sum(1 for college in colleges if college["net_price_0_30k"] is not None)
    with_gpa = sum(1 for school in cds if school.get("gpa_pct"))
    with_ed = sum(1 for school in cds if school.get("ed_applicants") and school.get("ed_admitted"))
    manifest = {
        "colleges": len(colleges),
        "colleges_with_admit_rate": with_admit,
        "colleges_with_sat_middle_50": with_scores,
        "colleges_with_net_price_by_income": with_price,
        "bachelor_program_rows": len(programs),
        "cds_schools": len(cds),
        "cds_with_gpa_distribution": with_gpa,
        "cds_with_early_decision_counts": with_ed,
        "womens_colleges": sum(1 for college in colleges if college["womens_college"]),
        "colleges_with_earnings_10yr": sum(1 for college in colleges if college["earnings_10yr"] is not None),
        "programs_with_earnings_1yr": sum(1 for row in programs if row["earnings_1yr"] is not None),
        "zip_centroids": zip_count,
        "majors": len(MAJORS),
        "sources": {
            "directory": "IPEDS HD2024",
            "admissions": "IPEDS ADM2023 (fall 2023 cohort)",
            "enrollment": "IPEDS EF2023A undergraduate total",
            "tuition": "IPEDS IC2023_AY (2023-24 published charges)",
            "net_price": "IPEDS SFA2223 (2022-23 average net price by income)",
            "graduation": "IPEDS DRVGR2023 bachelor's 4-year and 6-year rates",
            "programs": "IPEDS C2023_A bachelor's awards by CIP",
            "common_data_set": "collegedata.fyi public API, CDS years 2024-25 and 2025-26",
            "outcomes": "College Scorecard institution file, June 10 2026 release",
            "program_earnings": "College Scorecard field of study, bachelor's credential, 1-year median earnings",
            "womens_colleges": "Women's College Coalition current members, matched by UNITID",
            "zip_centroids": "Census 2025 ZCTA gazetteer",
            "majors": "CIP 2020 prefixes in scripts/majors.py",
        },
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    main()
