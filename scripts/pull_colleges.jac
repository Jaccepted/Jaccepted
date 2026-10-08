"""Pull college data for matching.

Run from the repo root:

    jac run scripts/pull_colleges.jac

Raw downloads land in data/raw/. Matching tables land in data/.
"""

import csv;
import hashlib;
import io;
import json;
import os;
import time;
import urllib.error;
import urllib.parse;
import urllib.request;
import zipfile;
import from pathlib { Path }
import from ..majors { MAJORS }

glob WOMENS_COLLEGES: list[str] = [
    "138600", "238193", "189097", "164632", "197993", "139199", "211273",
    "211468", "174747", "181604", "217961", "177117", "232308", "198950",
    "176035", "214148", "166939", "239390", "119173", "152390", "199607",
    "123165", "167783", "167835", "141060", "175005", "179548", "229179",
    "131876", "168218", "141325"
];

glob SCORECARD: dict[str, str] = {
    "scorecard_institution.zip": "https://ed-public-download.scorecard.network/downloads/Most-Recent-Cohorts-Institution_06102026.zip",
    "scorecard_field.zip": "https://ed-public-download.scorecard.network/downloads/Most-Recent-Cohorts-Field-of-Study_06102026.zip"
};

glob ZCTA_URL: str = "https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2025_Gazetteer/2025_Gaz_zcta_national.zip";
glob ROOT: any = Path(os.path.dirname(__file__)).resolve().parent;
glob RAW: any = ROOT / "data" / "raw";
glob OUT: any = ROOT / "data";

glob IPEDS: dict[str, str] = {
    "HD2024.zip": "https://nces.ed.gov/ipeds/datacenter/data/HD2024.zip",
    "IC2023.zip": "https://nces.ed.gov/ipeds/datacenter/data/IC2023.zip",
    "IC2023_AY.zip": "https://nces.ed.gov/ipeds/datacenter/data/IC2023_AY.zip",
    "ADM2023.zip": "https://nces.ed.gov/ipeds/datacenter/data/ADM2023.zip",
    "EF2023A.zip": "https://nces.ed.gov/ipeds/datacenter/data/EF2023A.zip",
    "SFA2223.zip": "https://nces.ed.gov/ipeds/datacenter/data/SFA2223.zip",
    "DRVGR2023.zip": "https://nces.ed.gov/ipeds/datacenter/data/DRVGR2023.zip",
    "C2023_A.zip": "https://nces.ed.gov/ipeds/datacenter/data/C2023_A.zip"
};

# Public read-only key published by collegedata.fyi.
glob CDS_KEY: str = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlzZHV3bXlndm1kb3pocHZ6YWl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxMDk3NTksImV4cCI6MjA5MTY4NTc1OX0.fYZOIHyrOWzidgc-CVxWCY5Fe9pQk12-6YjDIS6y9qs";
glob CDS_API: str = "https://api.collegedata.fyi/rest/v1";

glob STATES: list[str] = [
    "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA",
    "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA",
    "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY",
    "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX",
    "UT", "VT", "VA", "WA", "WV", "WI", "WY"
];

glob REGIONS: dict[str, str] = {
    "1": "Northeast", "2": "Northeast",
    "3": "Midwest", "4": "Midwest",
    "5": "South", "6": "South",
    "7": "West", "8": "West"
};

glob STATE_REGIONS: dict[str, str] = {
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
    "HI": "West", "OR": "West", "WA": "West"
};

glob LOCALES: dict[str, list[any]] = {
    "11": ["city_large", "urban"],
    "12": ["city_midsize", "urban"],
    "13": ["city_small", "urban"],
    "21": ["suburb_large", "suburban"],
    "22": ["suburb_midsize", "suburban"],
    "23": ["suburb_small", "suburban"],
    "31": ["town_fringe", "town"],
    "32": ["town_distant", "town"],
    "33": ["town_remote", "town"],
    "41": ["rural_fringe", "rural"],
    "42": ["rural_distant", "rural"],
    "43": ["rural_remote", "rural"]
};

glob CONTROLS: dict[str, str] = {"1": "public", "2": "private_nonprofit", "3": "private_forprofit"};
glob CONSIDERED: dict[str, str] = {"1": "required", "5": "considered_if_submitted", "3": "not_considered"};
glob TEST_POLICY: dict[str, str] = {"1": "required", "5": "test_optional", "3": "test_blind"};

glob CIP2: dict[str, str] = {
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
    "54": "History"
};

glob GPA_FIELDS: dict[str, str] = {
    "C.1121": "4.0",
    "C.1122": "3.75_3.99",
    "C.1123": "3.50_3.74",
    "C.1124": "3.25_3.49",
    "C.1125": "3.00_3.24",
    "C.1126": "2.50_2.99",
    "C.1127": "2.00_2.49",
    "C.1128": "1.00_1.99",
    "C.1129": "below_1.0"
};

glob BROWSER_COLUMNS: str = "ipeds_id,school_id,school_name,canonical_year,applied,admitted,acceptance_rate,yield_rate,enrolled_first_year,sat_submit_rate,act_submit_rate,sat_ebrw_p25,sat_ebrw_p50,sat_ebrw_p75,sat_math_p25,sat_math_p50,sat_math_p75,sat_composite_p25,sat_composite_p50,sat_composite_p75,act_composite_p25,act_composite_p50,act_composite_p75,ed_offered,ed_applicants,ed_admitted,ea_offered,ea_restrictive,archive_url,data_quality_flag";

def download(name: str, url: str) -> any {
    RAW.mkdir(parents=True, exist_ok=True);
    dest = RAW / name;
    if dest.exists() and dest.stat().st_size > 0 {
        return dest;
    }
    print(f"downloading {name}");
    request = urllib.request.Request(url, headers={"User-Agent": "Jaccepted/0.1"});
    with urllib.request.urlopen(request, timeout=180) as response {
        dest.write_bytes(response.read());
    }
    return dest;
}

def blank(value: any) -> str {
    if value is None {
        return "";
    }
    return str(value).strip();
}

def num(value: any) -> any {
    text = blank(value);
    if text == "" or text == "." or text == "-" {
        return None;
    }
    try {
        number = float(text);
    } except ValueError {
        return None;
    }
    if number < 0 {
        return None;
    }
    return number;
}

def signed_num(value: any) -> any {
    text = blank(value);
    if text == "" or text == "." or text == "-" {
        return None;
    }
    try {
        return float(text);
    } except ValueError {
        return None;
    }
}

def whole(value: any) -> any {
    number = num(value);
    if number is None {
        return None;
    }
    return int(number);
}

def ratio(part: any, whole_value: any) -> any {
    if part is None or whole_value is None or whole_value <= 0 {
        return None;
    }
    return round(part / whole_value, 6);
}

def percent_rate(value: any) -> any {
    number = num(value);
    if number is None {
        return None;
    }
    return round(number / 100, 6);
}

def money(value: any) -> any {
    return whole(value);
}

def add_money(left: any, right: any) -> any {
    if left is None or right is None {
        return None;
    }
    return left + right;
}

def size_band(enrollment: any) -> any {
    if enrollment is None {
        return None;
    }
    if enrollment < 5000 {
        return "small";
    }
    if enrollment <= 15000 {
        return "medium";
    }
    return "large";
}

def cleaned_row(row: dict[str, any]) -> dict[str, any] {
    clean: dict[str, any] = {};
    for pair in row.items() {
        key = pair[0];
        value = pair[1];
        name = blank(key);
        if isinstance(value, str) {
            clean[name] = value.strip();
        } else {
            clean[name] = value;
        }
    }
    return clean;
}

def iter_csv(zip_path: any, prefer: str = "") -> list[dict[str, any]] {
    found: list[dict[str, any]] = [];
    with zipfile.ZipFile(zip_path) as archive {
        names: list[str] = [];
        for name in archive.namelist() {
            if name.lower().endswith(".csv") {
                names.append(name);
            }
        }
        member = names[0];
        if prefer {
            for name in names {
                if name.lower() == prefer.lower() {
                    member = name;
                }
            }
        }
        with archive.open(member) as handle {
            text = io.TextIOWrapper(handle, encoding="utf-8-sig", newline="");
            for row in csv.DictReader(text) {
                found.append(cleaned_row(row));
            }
        }
    }
    return found;
}

def index_by_unit(rows: list[dict[str, any]], columns: list[str]) -> dict[str, dict[str, any]] {
    indexed = {};
    for row in rows {
        unit = row.get("UNITID", "");
        if unit {
            picked = {};
            for column in columns {
                picked[column] = row.get(column, "");
            }
            indexed[unit] = picked;
        }
    }
    return indexed;
}

def price_bands(costs: dict[str, any], prefix: str) -> dict[str, any] {
    return {
        "0_30": money(costs.get(prefix + "412")),
        "30_48": money(costs.get(prefix + "422")),
        "48_75": money(costs.get(prefix + "432")),
        "75_110": money(costs.get(prefix + "442")),
        "110_plus": money(costs.get(prefix + "452"))
    };
}

def bands_missing(bands: dict[str, any]) -> bool {
    for value in bands.values() {
        if value is not None {
            return False;
        }
    }
    return True;
}

def load_ipeds -> list[any] {
    for pair in IPEDS.items() {
        download(str(pair[0]), str(pair[1]));
    }
    directory = index_by_unit(iter_csv(RAW / "HD2024.zip"), [
        "INSTNM", "CITY", "STABBR", "SECTOR", "CONTROL", "DEGGRANT", "CYACTIVE",
        "HBCU", "TRIBAL", "LOCALE", "OBEREG", "LATITUDE", "LONGITUD", "WEBADDR", "OPEID"
    ]);
    characteristics = index_by_unit(
        iter_csv(RAW / "IC2023.zip", "IC2023_RV.csv"),
        ["RELAFFIL", "OPENADMP", "ROOMAMT", "BOARDAMT", "RMBRDAMT", "APPLFEEU"]
    );
    charges = index_by_unit(iter_csv(RAW / "IC2023_AY.zip"), [
        "TUITION2", "FEE2", "TUITION3", "FEE3"
    ]);
    admissions = index_by_unit(iter_csv(RAW / "ADM2023.zip"), [
        "ADMCON1", "ADMCON7", "APPLCN", "ADMSSN", "ENRLT",
        "SATVR25", "SATVR75", "SATMT25", "SATMT75",
        "ACTCM25", "ACTCM75", "SATPCT", "ACTPCT"
    ]);
    aid = index_by_unit(iter_csv(RAW / "SFA2223.zip"), [
        "NPIST2",
        "NPIS412", "NPIS422", "NPIS432", "NPIS442", "NPIS452",
        "NPT412", "NPT422", "NPT432", "NPT442", "NPT452"
    ]);
    graduation = index_by_unit(iter_csv(RAW / "DRVGR2023.zip"), ["GBA4RTT", "GBA6RTT"]);
    enrollment = {};
    for row in iter_csv(RAW / "EF2023A.zip") {
        if row.get("EFALEVEL") == "2" {
            enrollment[row["UNITID"]] = whole(row.get("EFTOTLT"));
        }
    }
    programs = {};
    for row in iter_csv(RAW / "C2023_A.zip", "C2023_a_RV.csv") {
        if row.get("AWLEVEL") != "5" {
            continue;
        }
        cip = row.get("CIPCODE", "");
        if cip == "" or cip == "99" or cip == "99.0000" {
            continue;
        }
        awards = whole(row.get("CTOTALT"));
        if not awards {
            continue;
        }
        key = row["UNITID"] + "|" + cip;
        programs[key] = programs.get(key, 0) + awards;
    }
    colleges: list[dict[str, any]] = [];
    for pair in directory.items() {
        unit = str(pair[0]);
        school = pair[1];
        if school["STABBR"] not in STATES {
            continue;
        }
        if school["SECTOR"] != "1" and school["SECTOR"] != "2" and school["SECTOR"] != "3" {
            continue;
        }
        if school["DEGGRANT"] != "1" or school["CYACTIVE"] != "1" {
            continue;
        }
        info = characteristics.get(unit, {});
        price = charges.get(unit, {});
        admit = admissions.get(unit, {});
        costs = aid.get(unit, {});
        grads = graduation.get(unit, {});
        applicants = whole(admit.get("APPLCN"));
        admitted = whole(admit.get("ADMSSN"));
        enrolled = whole(admit.get("ENRLT"));
        undergrad = enrollment.get(unit);
        locale_pair = LOCALES.get(school["LOCALE"], [None, None]);
        room_board = money(info.get("RMBRDAMT"));
        if room_board is None {
            room_board = add_money(money(info.get("ROOMAMT")), money(info.get("BOARDAMT")));
        }
        public = school["CONTROL"] == "1";
        band_prefix = "NPT";
        if public {
            band_prefix = "NPIS";
        }
        bands = price_bands(costs, band_prefix);
        if bands_missing(bands) {
            other = "NPIS";
            if public {
                other = "NPT";
            }
            bands = price_bands(costs, other);
        }
        affiliation = whole(info.get("RELAFFIL"));
        region = REGIONS.get(school["OBEREG"]);
        if not region {
            region = STATE_REGIONS.get(school["STABBR"]);
        }
        opeid = school["OPEID"];
        if not opeid {
            opeid = None;
        }
        website = school["WEBADDR"];
        if not website {
            website = None;
        }
        colleges.append({
            "unitid": unit,
            "opeid": opeid,
            "name": school["INSTNM"],
            "city": school["CITY"],
            "state": school["STABBR"],
            "region": region,
            "locale": locale_pair[0],
            "setting": locale_pair[1],
            "control": CONTROLS.get(school["CONTROL"]),
            "hbcu": school["HBCU"] == "1",
            "tribal_college": school["TRIBAL"] == "1",
            "religiously_affiliated": affiliation is not None and affiliation > 0,
            "open_admission": info.get("OPENADMP") == "1",
            "latitude": signed_num(school["LATITUDE"]),
            "longitude": signed_num(school["LONGITUD"]),
            "website": website,
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
            "bachelor_program_count": 0
        });
    }
    program_rows: list[dict[str, any]] = [];
    counts = {};
    college_ids = {};
    for college in colleges {
        college_ids[college["unitid"]] = True;
    }
    for pair in programs.items() {
        key = str(pair[0]);
        awards = pair[1];
        parts = key.split("|");
        unit = parts[0];
        cip = parts[1];
        if unit not in college_ids {
            continue;
        }
        cip2 = cip.split(".")[0].zfill(2)[:2];
        program_rows.append({
            "unitid": unit,
            "cip": cip,
            "cip_family": CIP2.get(cip2),
            "bachelor_awards": awards,
            "earnings_1yr": None
        });
        counts[unit] = counts.get(unit, 0) + 1;
    }
    for college in colleges {
        college["bachelor_program_count"] = counts.get(college["unitid"], 0);
    }
    colleges.sort(key=lambda (college: dict[str, any]) { return str(college["name"]) + str(college["unitid"]); });
    program_rows.sort(key=lambda (program: dict[str, any]) { return str(program["unitid"]) + str(program["cip"]); });
    return [colleges, program_rows];
}

def cds_get(path: str, params: dict[str, str]) -> list[dict[str, any]] {
    query = urllib.parse.urlencode(params);
    url = CDS_API + "/" + path + "?" + query;
    cache = RAW / "cds-cache" / (hashlib.sha256(url.encode()).hexdigest() + ".json");
    if cache.exists() {
        return json.loads(cache.read_text(encoding="utf-8"));
    }
    request = urllib.request.Request(url, headers={
        "apikey": CDS_KEY,
        "Authorization": "Bearer " + CDS_KEY,
        "Accept": "application/json",
        "User-Agent": "Jaccepted/0.1"
    });
    delay = 2;
    last_error = "unknown error";
    body = "";
    got = False;
    attempt = 0;
    while attempt < 4 {
        try {
            with urllib.request.urlopen(request, timeout=90) as response {
                body = response.read().decode("utf-8");
            }
            got = True;
            break;
        } except urllib.error.HTTPError as error {
            last_error = error.read().decode("utf-8", errors="replace");
            if "57014" not in last_error {
                raise RuntimeError("CDS " + path + " failed (" + str(error.code) + "): " + last_error);
            }
            time.sleep(delay);
            delay = delay * 2;
        }
        attempt = attempt + 1;
    }
    if not got {
        raise RuntimeError("CDS " + path + " timed out: " + last_error);
    }
    payload = json.loads(body);
    if not isinstance(payload, list) {
        raise RuntimeError("CDS " + path + " returned a non-list");
    }
    cache.parent.mkdir(parents=True, exist_ok=True);
    cache.write_text(body, encoding="utf-8");
    return payload;
}

def page_params(params: dict[str, str], offset: int) -> dict[str, str] {
    page: dict[str, str] = {};
    for pair in params.items() {
        page[str(pair[0])] = str(pair[1]);
    }
    page["limit"] = "1000";
    page["offset"] = str(offset);
    return page;
}

def cds_pages(path: str, params: dict[str, str]) -> list[dict[str, any]] {
    rows: list[dict[str, any]] = [];
    offset = 0;
    while True {
        page = cds_get(path, page_params(params, offset));
        for item in page {
            rows.append(item);
        }
        if len(page) < 1000 {
            return rows;
        }
        offset = offset + 1000;
    }
    return rows;
}

def newer(year: any, candidate: any) -> bool {
    if not candidate {
        return False;
    }
    if not year {
        return True;
    }
    return str(candidate) > str(year);
}

def published(row: dict[str, any]) -> any {
    text = row.get("value_text");
    if text is not None and text != "" {
        try {
            return float(text);
        } except ValueError {
            return str(text).strip();
        }
    }
    return row.get("value_num");
}

def empty_school(unit: str, year: str) -> dict[str, any] {
    return {
        "unitid": unit,
        "school_id": None,
        "name": None,
        "cds_year": year,
        "source": "https://www.collegedata.fyi",
        "archive_url": None,
        "data_quality_flag": None,
        "gpa_pct": {}
    };
}

def load_cds -> list[dict[str, any]] {
    browser: list[dict[str, any]] = [];
    for year in ["2024-25", "2025-26"] {
        for item in cds_pages("school_browser_rows", {
            "select": BROWSER_COLUMNS,
            "canonical_year": "eq." + year,
            "order": "ipeds_id.asc"
        }) {
            browser.append(item);
        }
    }
    schools = {};
    for row in browser {
        if not row.get("ipeds_id") {
            continue;
        }
        unit = str(row["ipeds_id"]).zfill(6);
        current = schools.get(unit);
        if current and not newer(current["cds_year"], row.get("canonical_year")) {
            continue;
        }
        admitted = row.get("ed_admitted");
        applicants = row.get("ed_applicants");
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
            "test_importance": None
        };
    }
    field_ids = {};
    for pair in GPA_FIELDS.items() {
        field_ids[str(pair[0])] = pair[1];
    }
    field_ids["C.1201"] = "gpa_average";
    field_ids["C.1202"] = "gpa_submit";
    field_ids["C.801"] = "uses_tests";
    field_ids["C.802"] = "test_policy";
    field_ids["C.703"] = "gpa_importance";
    field_ids["C.704"] = "test_importance";
    field_ids["C.120"] = "in_state_applied";
    field_ids["C.121"] = "in_state_admitted";
    field_ids["C.123"] = "out_of_state_applied";
    field_ids["C.124"] = "out_of_state_admitted";
    latest = {};
    for field_id in field_ids.keys() {
        print("cds field " + field_id);
        rows: list[dict[str, any]] = [];
        for year in ["2024-25", "2025-26"] {
            for item in cds_pages("cds_fields", {
                "select": "ipeds_id,canonical_year,value_num,value_text",
                "field_id": "eq." + field_id,
                "canonical_year": "eq." + year
            }) {
                rows.append(item);
            }
        }
        for row in rows {
            if not row.get("ipeds_id") {
                continue;
            }
            unit = str(row["ipeds_id"]).zfill(6);
            year = row.get("canonical_year") or "";
            key = unit + "|" + field_id;
            previous = latest.get(key);
            if previous and previous[0] >= year {
                continue;
            }
            latest[key] = [year, row];
        }
    }
    count_fields = ["in_state_applied", "in_state_admitted", "out_of_state_applied", "out_of_state_admitted"];
    text_fields = ["test_policy", "gpa_importance", "test_importance"];
    for pair in latest.items() {
        key = str(pair[0]);
        packed = pair[1];
        parts = key.split("|");
        unit = parts[0];
        field_id = parts[1];
        row = packed[1];
        year = packed[0];
        if unit not in schools {
            schools[unit] = empty_school(unit, year);
        }
        school = schools[unit];
        value = published(row);
        if field_id in GPA_FIELDS {
            if isinstance(value, float) {
                if "gpa_pct" not in school {
                    school["gpa_pct"] = {};
                }
                school["gpa_pct"][GPA_FIELDS[field_id]] = value;
            }
            continue;
        }
        target = field_ids[field_id];
        if target == "gpa_average" {
            school["gpa_average"] = None;
            if isinstance(value, float) {
                school["gpa_average"] = value;
            }
        } elif target == "gpa_submit" {
            school["gpa_submit_rate"] = None;
            if isinstance(value, float) {
                school["gpa_submit_rate"] = round(value / 100, 6);
            }
        } elif target == "uses_tests" {
            school["uses_test_scores"] = row.get("value_text") or None;
        } elif target in text_fields {
            school[target] = row.get("value_text") or None;
        } elif target in count_fields {
            school[target] = None;
            if isinstance(value, float) {
                school[target] = int(value);
            }
        }
    }
    for school in schools.values() {
        school["in_state_admit_rate"] = ratio(school.get("in_state_admitted"), school.get("in_state_applied"));
        school["out_of_state_admit_rate"] = ratio(school.get("out_of_state_admitted"), school.get("out_of_state_applied"));
        if "gpa_pct" not in school {
            school["gpa_pct"] = {};
        }
    }
    records: list[dict[str, any]] = [];
    for school in schools.values() {
        if school.get("unitid") {
            records.append(school);
        }
    }
    records.sort(key=lambda (school: dict[str, any]) { return str(school.get("name") or "") + str(school["unitid"]); });
    return records;
}

def scorecard_number(value: any) -> any {
    text = blank(value);
    if text == "" or text == "NULL" or text == "NA" or text == "PS" or text == "PrivacySuppressed" {
        return None;
    }
    return num(text);
}

def fraction(value: any) -> any {
    number = scorecard_number(value);
    if number is None {
        return None;
    }
    if number > 1 {
        number = number / 100;
    }
    return round(number, 6);
}

def cip4(cip: str) -> str {
    digits = "";
    for character in cip {
        if character.isdigit() {
            digits = digits + character;
        }
    }
    return digits[:4];
}

def money_from(value: any) -> any {
    number = scorecard_number(value);
    if number is None {
        return None;
    }
    return int(number);
}

def iter_scorecard(zip_name: str, member: str) -> list[dict[str, any]] {
    found: list[dict[str, any]] = [];
    with zipfile.ZipFile(RAW / zip_name) as archive {
        with archive.open(member) as handle {
            text = io.TextIOWrapper(handle, encoding="utf-8", newline="");
            for row in csv.DictReader(text) {
                found.append(cleaned_row(row));
            }
        }
    }
    return found;
}

def attach_scorecard(colleges: list[dict[str, any]], programs: list[dict[str, any]]) -> None {
    for pair in SCORECARD.items() {
        download(str(pair[0]), str(pair[1]));
    }
    by_id = {};
    for college in colleges {
        by_id[college["unitid"]] = college;
    }
    for row in iter_scorecard("scorecard_institution.zip", "Most-Recent-Cohorts-Institution.csv") {
        college = by_id.get(row.get("UNITID", ""));
        if college is None {
            continue;
        }
        college["earnings_6yr"] = money_from(row.get("MD_EARN_WNE_P6"));
        college["earnings_10yr"] = money_from(row.get("MD_EARN_WNE_P10"));
        college["median_debt"] = money_from(row.get("DEBT_MDN"));
        college["pell_share"] = fraction(row.get("PCTPELL"));
        college["retention_rate"] = fraction(row.get("RET_FT4"));
        college["first_gen_share"] = fraction(row.get("FIRST_GEN"));
    }
    earnings = {};
    for row in iter_scorecard("scorecard_field.zip", "Most-Recent-Cohorts-Field-of-Study.csv") {
        if row.get("CREDLEV") != "3" {
            continue;
        }
        amount = money_from(row.get("EARN_MDN_1YR"));
        if amount is None {
            continue;
        }
        earnings[row.get("UNITID", "") + "|" + cip4(blank(row.get("CIPCODE", "")))] = amount;
    }
    for program in programs {
        program["earnings_1yr"] = earnings.get(program["unitid"] + "|" + cip4(program["cip"]));
    }
}

def write_majors -> None {
    payload: list[dict[str, any]] = [];
    for row in MAJORS {
        payload.append({"name": row[0], "cip_prefixes": row[1]});
    }
    (OUT / "majors.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8");
}

def write_jsonl(path: any, rows: list[dict[str, any]]) -> None {
    with path.open("w", encoding="utf-8") as handle {
        for row in rows {
            handle.write(json.dumps(row, ensure_ascii=False) + "\n");
        }
    }
}

def write_zip_centroids -> int {
    download("zcta2025.zip", ZCTA_URL);
    rows: list[dict[str, any]] = [];
    with zipfile.ZipFile(RAW / "zcta2025.zip") as archive {
        member = "";
        for name in archive.namelist() {
            if name.endswith(".txt") {
                member = name;
            }
        }
        with archive.open(member) as handle {
            text = io.TextIOWrapper(handle, encoding="utf-8-sig", newline="");
            for row in csv.DictReader(text, delimiter="|") {
                code = blank(row.get("GEOID")).zfill(5);
                latitude = signed_num(row.get("INTPTLAT"));
                longitude = signed_num(row.get("INTPTLONG"));
                if len(code) != 5 or latitude is None or longitude is None {
                    continue;
                }
                rows.append({"zip": code, "latitude": latitude, "longitude": longitude});
            }
        }
    }
    rows.sort(key=lambda (item: dict[str, any]) { return str(item["zip"]); });
    cambridge = None;
    for row in rows {
        if row["zip"] == "02138" {
            cambridge = row;
        }
    }
    if cambridge is None or not (42.3 < cambridge["latitude"] < 42.5 and -71.2 < cambridge["longitude"] < -71.0) {
        raise SystemExit("Cambridge ZIP centroid looks wrong");
    }
    if len(rows) < 30000 {
        raise SystemExit("Expected tens of thousands of ZIP centroids");
    }
    write_jsonl(OUT / "zip_centroids.jsonl", rows);
    return len(rows);
}

def fail(message: str) -> None {
    raise SystemExit(message);
}

def check(colleges: list[dict[str, any]], programs: list[dict[str, any]], cds: list[dict[str, any]]) -> None {
    by_id = {};
    for college in colleges {
        by_id[college["unitid"]] = college;
    }
    harvard = by_id["166027"];
    michigan = by_id["170976"];
    texas = by_id["228778"];
    florida = by_id["134130"];
    if not (0.01 < harvard["admit_rate"] < 0.10) {
        fail("Harvard admit rate looks wrong");
    }
    if not (michigan["tuition_in_state"] < michigan["tuition_out_of_state"]) {
        fail("Michigan in-state tuition should be below out-of-state");
    }
    if texas["region"] != "South" or texas["state"] != "TX" {
        fail("UT Austin region was not mapped to the South");
    }
    if florida["test_policy"] != "required" or harvard["test_policy"] != "test_optional" {
        fail("Test-policy labels do not match known schools");
    }
    if harvard["net_price_0_30k"] is None or michigan["net_price_0_30k"] is None {
        fail("Net price by income is missing for Harvard or Michigan");
    }
    harvard_programs: list[dict[str, any]] = [];
    found_cs = False;
    computer_science = None;
    for row in programs {
        if row["unitid"] == "166027" {
            harvard_programs.append(row);
            if str(row["cip"]).startswith("11.") {
                found_cs = True;
            }
            if row["cip"] == "11.0701" {
                computer_science = row;
            }
        }
    }
    if not found_cs {
        fail("Harvard is missing computer-science bachelor's awards");
    }
    found_harvard_cds = False;
    for row in cds {
        if row["unitid"] == "166027" {
            found_harvard_cds = True;
        }
    }
    if not found_harvard_cds {
        fail("Harvard is missing from the Common Data Set extract");
    }
    if harvard["earnings_10yr"] is None or harvard["earnings_10yr"] < 50000 {
        fail("Harvard 10-year earnings look wrong");
    }
    if harvard["womens_college"] or not by_id["168218"]["womens_college"] or not by_id["167835"]["womens_college"] {
        fail("Women's college flags are wrong for Harvard, Wellesley, or Smith");
    }
    if computer_science is None or computer_science["earnings_1yr"] is None or abs(int(computer_science["earnings_1yr"]) - 152251) > 1 {
        fail("Harvard computer science earnings look wrong");
    }
    womens = 0;
    for college in colleges {
        if college["womens_college"] {
            womens = womens + 1;
        }
    }
    if womens != 31 {
        fail("Expected 31 women's colleges");
    }
    if harvard["longitude"] is None or harvard["longitude"] > -70 {
        fail("Harvard longitude looks wrong");
    }
}

def counted(rows: list[dict[str, any]], key: str) -> int {
    total = 0;
    for row in rows {
        if row.get(key) is not None {
            total = total + 1;
        }
    }
    return total;
}

def main -> None {
    OUT.mkdir(parents=True, exist_ok=True);
    loaded = load_ipeds();
    colleges = loaded[0];
    programs = loaded[1];
    attach_scorecard(colleges, programs);
    cds = load_cds();
    check(colleges, programs, cds);
    write_jsonl(OUT / "colleges.jsonl", colleges);
    write_jsonl(OUT / "programs.jsonl", programs);
    write_jsonl(OUT / "cds.jsonl", cds);
    write_majors();
    zip_count = write_zip_centroids();
    with_gpa = 0;
    with_ed = 0;
    womens = 0;
    with_earn = 0;
    program_earn = 0;
    for school in cds {
        if school.get("gpa_pct") {
            with_gpa = with_gpa + 1;
        }
        if school.get("ed_applicants") and school.get("ed_admitted") {
            with_ed = with_ed + 1;
        }
    }
    for college in colleges {
        if college["womens_college"] {
            womens = womens + 1;
        }
        if college["earnings_10yr"] is not None {
            with_earn = with_earn + 1;
        }
    }
    for row in programs {
        if row["earnings_1yr"] is not None {
            program_earn = program_earn + 1;
        }
    }
    manifest = {
        "colleges": len(colleges),
        "colleges_with_admit_rate": counted(colleges, "admit_rate"),
        "colleges_with_sat_middle_50": counted(colleges, "sat_reading_p25"),
        "colleges_with_net_price_by_income": counted(colleges, "net_price_0_30k"),
        "bachelor_program_rows": len(programs),
        "cds_schools": len(cds),
        "cds_with_gpa_distribution": with_gpa,
        "cds_with_early_decision_counts": with_ed,
        "womens_colleges": womens,
        "colleges_with_earnings_10yr": with_earn,
        "programs_with_earnings_1yr": program_earn,
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
            "majors": "CIP 2020 prefixes in majors.jac"
        }
    };
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8");
    print(json.dumps(manifest, indent=2));
}

with entry:__main__ {
    main();
}
