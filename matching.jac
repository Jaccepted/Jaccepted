"""Match a student profile to colleges.

Follows SPEC.md section 6.3 in three stages:
1. Hard filters drop colleges that fail a must-have preference.
2. Each remaining college gets a Reach, Target, or Likely bucket.
3. A 0-100 fit score ranks colleges inside each bucket.

College tables load once from data/ when the server starts.
"""

import json;
import math;
import os;
import from .majors { MAJORS }
import from .intake_rules { parse_num }

glob SHOW_PER_BUCKET: int = 25;
glob MIN_APPLICANTS: int = 50;
glob SHORTLIST: dict[str, int] = {"reach": 3, "target": 4, "likely": 3};

glob PRICE_KEYS: dict[str, str] = {
    "0-30000": "net_price_0_30k",
    "30001-48000": "net_price_30_48k",
    "48001-75000": "net_price_48_75k",
    "75001-110000": "net_price_75_110k",
    "110001+": "net_price_110k_plus"
};

# Common letter-grade cutoffs for converting a 100-point GPA to 4.0.
glob HUNDRED_SCALE: list[list[float]] = [
    [93.0, 4.0], [90.0, 3.7], [87.0, 3.3], [83.0, 3.0], [80.0, 2.7],
    [77.0, 2.3], [73.0, 2.0], [70.0, 1.7], [67.0, 1.3], [65.0, 1.0]
];

"""What the intake form collects, as the form stores it."""
obj Profile {
    has gpa_unweighted: str = "",
        gpa_scale: str = "4.0",
        test_plan: str = "none",
        sat_total: str = "",
        act_composite: str = "",
        undecided: str = "no",
        major1: str = "",
        major2: str = "",
        major3: str = "",
        regions: str = "",
        location_importance: str = "ignore",
        setting: str = "",
        setting_importance: str = "ignore",
        distance: str = "",
        distance_importance: str = "ignore",
        size_small: str = "yes",
        size_medium: str = "yes",
        size_large: str = "yes",
        size_importance: str = "ignore",
        want_public: str = "yes",
        want_private: str = "yes",
        control_importance: str = "ignore",
        religious: str = "",
        religious_importance: str = "ignore",
        want_hbcu: str = "no",
        hbcu_importance: str = "ignore",
        want_womens: str = "no",
        womens_importance: str = "ignore",
        max_price: str = "",
        price_importance: str = "ignore",
        outcomes_importance: str = "ignore",
        income_bracket: str = "",
        home_state: str = "",
        home_zip: str = "";
}

"""One college in the results, with the reasons behind its bucket and fit."""
obj CollegeMatch {
    has unitid: str,
        name: str,
        city: str,
        state: str,
        bucket: str,
        fit: int,
        admit_rate: float | None = None,
        net_price: int | None = None,
        miles: int | None = None,
        website: str = "",
        shortlist: bool = False,
        reasons: list[str] = [];
}

"""Matches grouped by bucket. Each list holds the best fits only; counts cover all."""
obj MatchResult {
    has reach: list[CollegeMatch] = [],
        target: list[CollegeMatch] = [],
        likely: list[CollegeMatch] = [],
        reach_count: int = 0,
        target_count: int = 0,
        likely_count: int = 0,
        considered: int = 0,
        notes: list[str] = [];
}

"""Everything the college page shows: stats, the student's standing, and why it fits."""
obj CollegeDetail {
    has found: bool = False,
        college: dict[str, any] = {},
        cds: dict[str, any] = {},
        bucket: str = "",
        fit: int = 0,
        reasons: list[str] = [],
        net_price: int | None = None,
        miles: int | None = None,
        program_count: int = 0;
}

def read_jsonl(name: str) -> list[dict[str, any]] {
    rows: list[dict[str, any]] = [];
    with open(os.path.join(DATA_DIR, name)) as handle {
        for line in handle {
            if line.strip() {
                rows.append(json.loads(line));
            }
        }
    }
    return rows;
}

def load_programs -> dict[str, list[str]] {
    by_unit: dict[str, list[str]] = {};
    for row in read_jsonl("programs.jsonl") {
        unit = str(row["unitid"]);
        if unit not in by_unit {
            by_unit[unit] = [];
        }
        by_unit[unit].append(str(row["cip"]));
    }
    return by_unit;
}

def load_cds -> dict[str, dict[str, any]] {
    by_unit: dict[str, dict[str, any]] = {};
    for row in read_jsonl("cds.jsonl") {
        by_unit[str(row["unitid"])] = row;
    }
    return by_unit;
}

def load_zips -> dict[str, list[float]] {
    by_zip: dict[str, list[float]] = {};
    for row in read_jsonl("zip_centroids.jsonl") {
        by_zip[str(row["zip"])] = [float(row["latitude"]), float(row["longitude"])];
    }
    return by_zip;
}

"""Four-year colleges with published admissions, or open admission."""
def load_colleges -> list[dict[str, any]] {
    kept: list[dict[str, any]] = [];
    for row in read_jsonl("colleges.jsonl") {
        if not row["bachelor_program_count"] {
            continue;
        }
        # A rate from a handful of applicants (0 of 1, say) is noise, not selectivity.
        if row["applicants"] is not None and row["applicants"] < MIN_APPLICANTS {
            row["admit_rate"] = None;
        }
        if row["admit_rate"] is None and not row["open_admission"] {
            continue;
        }
        kept.append(row);
    }
    return kept;
}

glob DATA_DIR: str = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data");
glob COLLEGES: list[dict[str, any]] = load_colleges();
glob PROGRAMS: dict[str, list[str]] = load_programs();
glob CDS: dict[str, dict[str, any]] = load_cds();
glob ZIPS: dict[str, list[float]] = load_zips();

def weight(importance: str) -> float {
    if importance == "must" {
        return 2.0;
    }
    if importance == "nice" {
        return 1.0;
    }
    return 0.0;
}

def money(value: float) -> str {
    return "$" + f"{int(round(value)):,}";
}

def percent(value: float) -> str {
    return str(int(round(value * 100))) + "%";
}

def gpa_on_four(raw: str, scale: str) -> float | None {
    value = parse_num(raw);
    if value is None {
        return None;
    }
    if scale == "5.0" {
        return value / 5.0 * 4.0;
    }
    if scale == "100" {
        for step in HUNDRED_SCALE {
            if value >= step[0] {
                return step[1];
            }
        }
        return 0.0;
    }
    return value;
}

"""Each recognized major as [name, CIP prefixes]. Free-text majors are skipped."""
def chosen_majors(profile: Profile) -> list[list[any]] {
    if profile.undecided == "yes" {
        return [];
    }
    chosen: list[list[any]] = [];
    for raw in [profile.major1, profile.major2, profile.major3] {
        wanted = raw.strip().lower();
        if not wanted {
            continue;
        }
        for major in MAJORS {
            if str(major[0]).lower() == wanted {
                chosen.append(major);
            }
        }
    }
    return chosen;
}

def offers(unitid: str, prefixes: list[str]) -> bool {
    for cip in PROGRAMS.get(unitid, []) {
        for prefix in prefixes {
            if cip.startswith(prefix) {
                return True;
            }
        }
    }
    return False;
}

def net_price_for(college: dict[str, any], bracket: str) -> float | None {
    key = PRICE_KEYS.get(bracket, "");
    if key and college[key] is not None {
        return float(college[key]);
    }
    if college["net_price"] is not None {
        return float(college["net_price"]);
    }
    # Many colleges publish prices only by income bracket; use their mean.
    known = [float(college[column]) for column in PRICE_KEYS.values() if college[column] is not None];
    if known {
        return sum(known) / len(known);
    }
    return None;
}

def miles_between(home: list[float], college: dict[str, any]) -> float | None {
    if college["latitude"] is None or college["longitude"] is None {
        return None;
    }
    lat1 = math.radians(home[0]);
    lat2 = math.radians(float(college["latitude"]));
    dlat = lat2 - lat1;
    dlon = math.radians(float(college["longitude"]) - home[1]);
    a = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2;
    return 3958.8 * 2 * math.asin(math.sqrt(a));
}

def setting_matches(wanted: str, setting: str) -> bool {
    if wanted == "rural" {
        return setting == "rural" or setting == "town";
    }
    return wanted == setting;
}

def sizes_wanted(profile: Profile) -> list[str] {
    sizes: list[str] = [];
    if profile.size_small == "yes" {
        sizes.append("small");
    }
    if profile.size_medium == "yes" {
        sizes.append("medium");
    }
    if profile.size_large == "yes" {
        sizes.append("large");
    }
    return sizes;
}

def control_matches(profile: Profile, control: str) -> bool {
    if control == "public" {
        return profile.want_public == "yes";
    }
    return profile.want_private == "yes";
}

def religious_matches(wanted: str, affiliated: bool) -> bool {
    if wanted == "religious" {
        return affiliated;
    }
    if wanted == "secular" {
        return not affiliated;
    }
    return True;
}

"""The reason a college fails a must-have, or "" when it passes them all."""
def must_have_failure(
    profile: Profile,
    college: dict[str, any],
    majors: list[list[any]],
    home: list[float] | None
) -> str {
    unit = str(college["unitid"]);
    if majors {
        found = False;
        for major in majors {
            if offers(unit, major[1]) {
                found = True;
            }
        }
        if not found {
            return "major";
        }
    }
    regions = [part for part in profile.regions.split(",") if part];
    if profile.location_importance == "must" and regions and college["region"] not in regions {
        return "region";
    }
    if profile.setting_importance == "must" and profile.setting and not setting_matches(profile.setting, college["setting"]) {
        return "setting";
    }
    limit = parse_num(profile.distance);
    if profile.distance_importance == "must" and limit is not None and home is not None {
        miles = miles_between(home, college);
        if miles is None or miles > limit {
            return "distance";
        }
    }
    sizes = sizes_wanted(profile);
    if profile.size_importance == "must" and len(sizes) < 3 and college["size_band"] not in sizes {
        return "size";
    }
    if profile.control_importance == "must" and not control_matches(profile, college["control"]) {
        return "type";
    }
    if profile.religious_importance == "must" and not religious_matches(profile.religious, bool(college["religiously_affiliated"])) {
        return "religion";
    }
    if profile.hbcu_importance == "must" and profile.want_hbcu == "yes" and not college["hbcu"] {
        return "hbcu";
    }
    if profile.womens_importance == "must" and profile.want_womens == "yes" and not college["womens_college"] {
        return "womens";
    }
    budget = parse_num(profile.max_price);
    if profile.price_importance == "must" and budget is not None {
        price = net_price_for(college, profile.income_bracket);
        if price is None or price > budget {
            return "price";
        }
    }
    return "";
}

def place(score: float, low: float, high: float) -> str {
    if score < low {
        return "below";
    }
    if score > high {
        return "above";
    }
    return "within";
}

def place_words(position: str) -> str {
    if position == "below" {
        return "below";
    }
    if position == "above" {
        return "above";
    }
    return "within";
}

"""Where the student's test score falls, as [position, sentence], or ["", ""]."""
def test_standing(profile: Profile, college: dict[str, any], cds: dict[str, any] | None) -> list[str] {
    if profile.test_plan == "sat" {
        score = parse_num(profile.sat_total);
        if score is None {
            return ["", ""];
        }
        low: float | None = None;
        high: float | None = None;
        if cds is not None and cds["sat_composite_p25"] is not None and cds["sat_composite_p75"] is not None {
            low = float(cds["sat_composite_p25"]);
            high = float(cds["sat_composite_p75"]);
        } elif college["sat_reading_p25"] is not None and college["sat_math_p25"] is not None and college["sat_reading_p75"] is not None and college["sat_math_p75"] is not None {
            low = float(college["sat_reading_p25"]) + float(college["sat_math_p25"]);
            high = float(college["sat_reading_p75"]) + float(college["sat_math_p75"]);
        }
        if low is None or high is None {
            return ["", ""];
        }
        position = place(score, low, high);
        return [
            position,
            f"Your SAT {int(score)} is {place_words(position)} their middle 50% ({int(low)}–{int(high)})."
        ];
    }
    if profile.test_plan == "act" {
        score = parse_num(profile.act_composite);
        if score is None {
            return ["", ""];
        }
        low_act = college["act_p25"];
        high_act = college["act_p75"];
        if (low_act is None or high_act is None) and cds is not None {
            low_act = cds["act_p25"];
            high_act = cds["act_p75"];
        }
        if low_act is None or high_act is None {
            return ["", ""];
        }
        position = place(score, float(low_act), float(high_act));
        return [
            position,
            f"Your ACT {int(score)} is {place_words(position)} their middle 50% ({int(low_act)}–{int(high_act)})."
        ];
    }
    return ["", ""];
}

"""Fallback standing from GPA against the Common Data Set average GPA."""
def gpa_standing(profile: Profile, cds: dict[str, any] | None) -> list[str] {
    if cds is None or cds["gpa_average"] is None {
        return ["", ""];
    }
    gpa = gpa_on_four(profile.gpa_unweighted, profile.gpa_scale);
    if gpa is None {
        return ["", ""];
    }
    average = float(cds["gpa_average"]);
    position = "within";
    if gpa >= average + 0.1 {
        position = "above";
    } elif gpa < average - 0.2 {
        position = "below";
    }
    words = "near";
    if position == "above" {
        words = "above";
    } elif position == "below" {
        words = "below";
    }
    return [position, f"Your GPA {gpa:.2f} is {words} their admitted average of {average:.2f}."];
}

"""Bucket from SPEC.md 6.3, with an admit-rate-only fallback when there is no score data."""
def bucket_for(admit: float | None, open_admission: bool, position: str) -> str {
    if admit is not None and admit < 0.15 {
        return "reach";
    }
    if position == "below" {
        return "reach";
    }
    if position == "above" {
        if admit is None or admit >= 0.5 {
            return "likely";
        }
        return "target";
    }
    if position == "within" {
        return "target";
    }
    if open_admission or admit is None {
        return "likely";
    }
    if admit < 0.35 {
        return "reach";
    }
    if admit >= 0.65 {
        return "likely";
    }
    return "target";
}

def scaled(value: float, low: float, high: float) -> float {
    if value <= low {
        return 0.0;
    }
    if value >= high {
        return 1.0;
    }
    return (value - low) / (high - low);
}

"""Fit score 0-100 and the reasons behind it."""
def fit_for(
    profile: Profile,
    college: dict[str, any],
    majors: list[list[any]],
    home: list[float] | None,
    price: float | None,
    miles: float | None
) -> list[any] {
    total = 0.0;
    weights = 0.0;
    reasons: list[str] = [];
    unit = str(college["unitid"]);
    if majors {
        offered = [str(major[0]) for major in majors if offers(unit, major[1])];
        total = total + 2.0 * len(offered) / len(majors);
        weights = weights + 2.0;
        if offered {
            reasons.append("Offers " + ", ".join(offered) + ".");
        }
    }
    regions = [part for part in profile.regions.split(",") if part];
    w = weight(profile.location_importance);
    if w and regions {
        weights = weights + w;
        if college["region"] in regions {
            total = total + w;
            reasons.append("In the " + college["region"] + ".");
        }
    }
    home_state = profile.home_state.strip();
    if home_state and str(college["state"]).strip() == home_state and str(college["control"]).startswith("public") {
        weights = weights + 1.0;
        total = total + 1.0;
        reasons.append("Public college in your home state.");
    }
    w = weight(profile.setting_importance);
    if w and profile.setting {
        weights = weights + w;
        if setting_matches(profile.setting, college["setting"]) {
            total = total + w;
            reasons.append(str(college["setting"]).capitalize() + " campus.");
        }
    }
    limit = parse_num(profile.distance);
    w = weight(profile.distance_importance);
    if w and limit is not None and home is not None {
        weights = weights + w;
        if miles is not None {
            if miles <= limit {
                total = total + w;
            } else {
                total = total + w * max(0.0, 1.0 - (miles - limit) / limit);
            }
        }
    }
    sizes = sizes_wanted(profile);
    w = weight(profile.size_importance);
    if w and len(sizes) < 3 {
        weights = weights + w;
        if college["size_band"] in sizes {
            total = total + w;
            reasons.append(str(college["size_band"]).capitalize() + " size.");
        }
    }
    w = weight(profile.control_importance);
    if w and not (profile.want_public == "yes" and profile.want_private == "yes") {
        weights = weights + w;
        if control_matches(profile, college["control"]) {
            total = total + w;
        }
    }
    w = weight(profile.religious_importance);
    if w and profile.religious {
        weights = weights + w;
        if religious_matches(profile.religious, bool(college["religiously_affiliated"])) {
            total = total + w;
        }
    }
    w = weight(profile.hbcu_importance);
    if w and profile.want_hbcu == "yes" {
        weights = weights + w;
        if college["hbcu"] {
            total = total + w;
            reasons.append("HBCU.");
        }
    }
    w = weight(profile.womens_importance);
    if w and profile.want_womens == "yes" {
        weights = weights + w;
        if college["womens_college"] {
            total = total + w;
            reasons.append("Women's college.");
        }
    }
    budget = parse_num(profile.max_price);
    w = weight(profile.price_importance);
    if w and budget is not None {
        weights = weights + w;
        if price is None {
            total = total + w * 0.5;
        } elif price <= budget {
            total = total + w;
            reasons.append("About " + money(price) + " a year after grants, within your budget.");
        } else {
            total = total + w * max(0.0, 1.0 - (price - budget) / max(budget, 1000.0));
            reasons.append("About " + money(price) + " a year after grants, over your budget.");
        }
    }
    w = weight(profile.outcomes_importance);
    if w {
        weights = weights + w;
        grad = college["grad_rate_6yr"];
        earnings = college["earnings_10yr"];
        parts: list[float] = [];
        if grad is not None {
            parts.append(float(grad));
        }
        if earnings is not None {
            parts.append(scaled(float(earnings), 30000.0, 100000.0));
        }
        if parts {
            total = total + w * sum(parts) / len(parts);
        } else {
            total = total + w * 0.5;
        }
        if grad is not None {
            reasons.append(percent(float(grad)) + " graduate within six years.");
        }
    }
    if weights == 0 {
        return [50, reasons];
    }
    return [int(round(100 * total / weights)), reasons];
}

def match_one(
    profile: Profile,
    college: dict[str, any],
    majors: list[list[any]],
    home: list[float] | None
) -> CollegeMatch {
    unit = str(college["unitid"]);
    cds = CDS.get(unit, None);
    admit = college["admit_rate"];
    if admit is None and cds is not None and cds["admit_rate"] is not None {
        admit = cds["admit_rate"];
    }
    standing = test_standing(profile, college, cds);
    if not standing[0] {
        standing = gpa_standing(profile, cds);
    }
    bucket = bucket_for(admit, bool(college["open_admission"]), standing[0]);
    reasons: list[str] = [];
    if admit is not None and admit < 0.15 {
        reasons.append("Admits " + percent(admit) + " of applicants, so it is a reach for everyone.");
    } elif standing[1] {
        reasons.append(standing[1]);
    } elif college["open_admission"] {
        reasons.append("Open admission.");
    } else {
        reasons.append("No score ranges published, so this uses the " + percent(admit) + " admit rate alone.");
    }
    if standing[1] and admit is not None and admit < 0.15 {
        reasons.append(standing[1]);
    }
    price = net_price_for(college, profile.income_bracket);
    miles: float | None = None;
    if home is not None {
        miles = miles_between(home, college);
    }
    fit = fit_for(profile, college, majors, home, price, miles);
    reasons = reasons + fit[1];
    if miles is not None {
        reasons.append(f"{int(round(miles)):,} miles from home.");
    }
    return CollegeMatch(
        unitid=unit,
        name=str(college["name"]),
        city=str(college["city"] or ""),
        state=str(college["state"] or ""),
        bucket=bucket,
        fit=fit[0],
        admit_rate=admit,
        net_price=(int(round(price)) if price is not None else None),
        miles=(int(round(miles)) if miles is not None else None),
        website=str(college["website"] or ""),
        reasons=reasons
    );
}

def ranked(matches: list[CollegeMatch], bucket: str) -> list[CollegeMatch] {
    group = [item for item in matches if item.bucket == bucket];
    group.sort(key=lambda (item: CollegeMatch) -> tuple[int, str] { return (-item.fit, item.name); });
    top = group[:SHOW_PER_BUCKET];
    for (index, item) in enumerate(top) {
        item.shortlist = index < SHORTLIST[bucket];
    }
    return top;
}

def match_profile(profile: Profile) -> MatchResult {
    majors = chosen_majors(profile);
    home: list[float] | None = None;
    zip_code = profile.home_zip.strip()[:5];
    if zip_code {
        home = ZIPS.get(zip_code, None);
    }
    notes: list[str] = [];
    if zip_code and home is None {
        notes.append("We could not find ZIP " + zip_code + ", so distance is not used.");
    }
    named = [raw.strip() for raw in [profile.major1, profile.major2, profile.major3] if raw.strip()];
    if profile.undecided != "yes" and len(named) > len(majors) {
        notes.append("Majors that are not on the suggested list are not used for matching yet.");
    }
    matches: list[CollegeMatch] = [];
    for college in COLLEGES {
        if must_have_failure(profile, college, majors, home) {
            continue;
        }
        matches.append(match_one(profile, college, majors, home));
    }
    reach = ranked(matches, "reach");
    target = ranked(matches, "target");
    likely = ranked(matches, "likely");
    return MatchResult(
        reach=reach,
        target=target,
        likely=likely,
        reach_count=len([item for item in matches if item.bucket == "reach"]),
        target_count=len([item for item in matches if item.bucket == "target"]),
        likely_count=len([item for item in matches if item.bucket == "likely"]),
        considered=len(COLLEGES),
        notes=notes
    );
}

"""Run matching for a submitted intake profile."""
def:pub match_colleges(profile: Profile) -> MatchResult {
    return match_profile(profile);
}

glob DETAIL_FIELDS: list[str] = [
    "unitid", "name", "city", "state", "region", "setting", "control", "website",
    "hbcu", "womens_college", "religiously_affiliated", "open_admission",
    "undergrad_enrollment", "size_band", "applicants", "admitted", "admit_rate",
    "yield_rate", "sat_reading_p25", "sat_reading_p75", "sat_math_p25", "sat_math_p75",
    "act_p25", "act_p75", "sat_submit_rate", "act_submit_rate",
    "tuition_in_state", "tuition_out_of_state", "room_and_board", "application_fee",
    "net_price", "net_price_0_30k", "net_price_30_48k", "net_price_48_75k",
    "net_price_75_110k", "net_price_110k_plus", "grad_rate_4yr", "grad_rate_6yr",
    "retention_rate", "earnings_6yr", "earnings_10yr", "median_debt", "pell_share",
    "first_gen_share"
];

glob DETAIL_CDS_FIELDS: list[str] = [
    "cds_year", "gpa_average", "ed_offered", "ed_admit_rate", "ea_offered",
    "in_state_admit_rate", "out_of_state_admit_rate", "sat_composite_p25",
    "sat_composite_p75", "act_p25", "act_p75"
];

"""Details for one college, scored against the student's profile like the results list."""
def:pub college_detail(unitid: str, profile: Profile) -> CollegeDetail {
    matches = [row for row in COLLEGES if str(row["unitid"]) == unitid];
    if not matches {
        return CollegeDetail();
    }
    college = matches[0];
    majors = chosen_majors(profile);
    home: list[float] | None = None;
    zip_code = profile.home_zip.strip()[:5];
    if zip_code {
        home = ZIPS.get(zip_code, None);
    }
    scored = match_one(profile, college, majors, home);
    cds = CDS.get(unitid, None);
    return CollegeDetail(
        found=True,
        college={field: college[field] for field in DETAIL_FIELDS},
        cds=({field: cds[field] for field in DETAIL_CDS_FIELDS} if cds is not None else {}),
        bucket=scored.bucket,
        fit=scored.fit,
        reasons=scored.reasons,
        net_price=scored.net_price,
        miles=scored.miles,
        program_count=len(PROGRAMS.get(unitid, []))
    );
}
