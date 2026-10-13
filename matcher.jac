"""College matching engine (server-side).

Loads colleges.jsonl, programs.jsonl, and zip_centroids.jsonl once at server
start, then filters and scores every eligible college against the student
profile on each call to match_colleges().
"""

import json;
import math;
import os;
import from pathlib { Path }
import from .majors { MAJORS }

# --- Wire-safe result types ---

obj MatchResult {
    has unitid: str,
        name: str,
        city: str,
        state: str,
        bucket: str,
        fit_score: int;
    has website: str = "",
        admit_rate: float | None = None,
        sat_composite_p25: int | None = None,
        sat_composite_p75: int | None = None,
        act_p25: int | None = None,
        act_p75: int | None = None,
        net_price_for_bracket: int | None = None,
        net_price: int | None = None,
        grad_rate_6yr: float | None = None,
        earnings_10yr: int | None = None,
        size_band: str = "",
        setting: str = "",
        control: str = "",
        hbcu: bool = False,
        womens_college: bool = False,
        bucket_reason: str = "",
        fit_reasons: list[str] = [];
}

obj MatchResponse {
    has reach: list[MatchResult],
        target: list[MatchResult],
        likely: list[MatchResult],
        total_filtered: int;
    has error: str = "";
}

obj CollegeDetail {
    has found: bool = False,
        college: dict[str, any] = {},
        cds: dict[str, any] = {},
        bucket: str = "",
        bucket_reason: str = "",
        fit_score: int = 0,
        fit_reasons: list[str] = [],
        price: int | None = None,
        distance_miles: int | None = None,
        program_count: int = 0;
}

# --- Data loading helpers (defined before the globs that call them) ---

glob DATA_DIR: any = Path(os.path.dirname(__file__)).resolve() / "data";

def _read_jsonl(path: any) -> list[any] {
    rows: list[any] = [];
    try {
        with path.open(encoding="utf-8") as f {
            for line in f {
                text = line.strip();
                if text {
                    rows.append(json.loads(text));
                }
            }
        }
    } except Exception {
        return [];
    }
    return rows;
}

def _build_programs_index(rows: list[any]) -> dict[str, list[str]] {
    idx: dict[str, list[str]] = {};
    for row in rows {
        uid = str(row.get("unitid", ""));
        cip = str(row.get("cip", ""));
        if uid and cip {
            if uid not in idx {
                idx[uid] = [];
            }
            idx[uid].append(cip);
        }
    }
    return idx;
}

def _build_zip_index(rows: list[any]) -> dict[str, list[float]] {
    idx: dict[str, list[float]] = {};
    for row in rows {
        code = str(row.get("zip", ""));
        lat = row.get("latitude");
        lon = row.get("longitude");
        if code and lat is not None and lon is not None {
            idx[code] = [float(lat), float(lon)];
        }
    }
    return idx;
}

# --- Cached data (loaded once at server start) ---

glob _colleges: list[any] = _read_jsonl(DATA_DIR / "colleges.jsonl");
glob _programs_index: dict[str, list[str]] = _build_programs_index(
    _read_jsonl(DATA_DIR / "programs.jsonl")
);
glob _zip_coords: dict[str, list[float]] = _build_zip_index(
    _read_jsonl(DATA_DIR / "zip_centroids.jsonl")
);

def _build_cds_index(rows: list[any]) -> dict[str, any] {
    idx: dict[str, any] = {};
    for row in rows {
        uid = str(row.get("unitid", ""));
        if uid {
            idx[uid] = row;
        }
    }
    return idx;
}

glob _cds_index: dict[str, any] = _build_cds_index(_read_jsonl(DATA_DIR / "cds.jsonl"));
glob _college_index: dict[str, any] = {str(c.get("unitid", "")): c for c in _colleges};

# --- Pure helpers ---

def _haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float {
    r = 3958.8;
    p1 = lat1 * math.pi / 180.0;
    p2 = lat2 * math.pi / 180.0;
    dp = (lat2 - lat1) * math.pi / 180.0;
    dl = (lon2 - lon1) * math.pi / 180.0;
    a = (math.sin(dp / 2.0) ** 2.0
        + math.cos(p1) * math.cos(p2) * math.sin(dl / 2.0) ** 2.0);
    return 2.0 * r * math.asin(math.sqrt(a));
}

def _parse_f(raw: str) -> float | None {
    text = raw.strip();
    if not text {
        return None;
    }
    try {
        return float(text);
    } except Exception {
        return None;
    }
}

def _major_cip_prefixes(names: list[str]) -> list[str] {
    prefixes: list[str] = [];
    for row in MAJORS {
        major_name = str(row[0]);
        for name in names {
            if major_name.lower() == name.lower().strip() {
                for prefix in (row[1] as list[str]) {
                    if prefix not in prefixes {
                        prefixes.append(prefix);
                    }
                }
            }
        }
    }
    return prefixes;
}

def _college_offers(unit: str, cip_prefixes: list[str]) -> bool {
    cips = _programs_index.get(unit, []);
    for cip in cips {
        for prefix in cip_prefixes {
            if cip.startswith(prefix) {
                return True;
            }
        }
    }
    return False;
}

def _price_for_bracket(college: any, income: str) -> int | None {
    if income == "0-30000" {
        return college.get("net_price_0_30k");
    }
    if income == "30001-48000" {
        return college.get("net_price_30_48k");
    }
    if income == "48001-75000" {
        return college.get("net_price_48_75k");
    }
    if income == "75001-110000" {
        return college.get("net_price_75_110k");
    }
    if income == "110001+" {
        return college.get("net_price_110k_plus");
    }
    return None;
}

def _effective_price(college: any, income: str) -> int | None {
    # Price for the student's income bracket if known; otherwise the school's
    # overall average net price; otherwise the mean of whichever brackets exist.
    price = _price_for_bracket(college, income);
    if price is not None {
        return price;
    }
    overall = college.get("net_price");
    if overall is not None {
        return overall;
    }
    vals: list[int] = [];
    for key in ["net_price_0_30k", "net_price_30_48k", "net_price_48_75k", "net_price_75_110k", "net_price_110k_plus"] {
        v = college.get(key);
        if v is not None {
            vals.append(int(v));
        }
    }
    if len(vals) == 0 {
        return None;
    }
    return int(round(sum(vals) / len(vals)));
}

def _importance_weight(level: str) -> float {
    if level == "must" {
        return 3.0;
    }
    if level == "nice" {
        return 1.5;
    }
    return 0.0;
}

# --- Hard filter: returns True if the college should be excluded ---

def _should_filter(college: any, profile: any,
                   home_coords: list[float] | None) -> bool {
    # Women's colleges excluded unless the student opts in
    if college.get("womens_college") and str(profile.get("want_womens", "no")) != "yes" {
        return True;
    }

    # Must-have: only HBCUs
    if (str(profile.get("want_hbcu", "no")) == "yes"
            and str(profile.get("hbcu_importance", "ignore")) == "must"
            and not college.get("hbcu")) {
        return True;
    }

    # Must-have: only women's colleges
    if (str(profile.get("want_womens", "no")) == "yes"
            and str(profile.get("womens_importance", "ignore")) == "must"
            and not college.get("womens_college")) {
        return True;
    }

    # Must-have: region
    if str(profile.get("location_importance", "ignore")) == "must" {
        raw = str(profile.get("regions", ""));
        selected = [r for r in raw.split(",") if r.strip()];
        if selected and str(college.get("region", "")) not in selected {
            return True;
        }
    }

    # Must-have: setting (urban/suburban/rural)
    pref_setting = str(profile.get("setting", ""));
    if (str(profile.get("setting_importance", "ignore")) == "must"
            and pref_setting
            and str(college.get("setting", "")) != pref_setting) {
        return True;
    }

    # Must-have: distance from home ZIP
    max_dist_raw = str(profile.get("distance", ""));
    if (str(profile.get("distance_importance", "ignore")) == "must"
            and max_dist_raw.strip() and home_coords is not None) {
        max_dist = _parse_f(max_dist_raw);
        col_lat = college.get("latitude");
        col_lon = college.get("longitude");
        if max_dist is not None and col_lat is not None and col_lon is not None {
            d = _haversine(home_coords[0], home_coords[1], float(col_lat), float(col_lon));
            if d > max_dist {
                return True;
            }
        }
    }

    # Must-have: size band
    if str(profile.get("size_importance", "ignore")) == "must" {
        band = college.get("size_band");
        ok = (
            (band == "small" and str(profile.get("size_small", "yes")) == "yes") or
            (band == "medium" and str(profile.get("size_medium", "yes")) == "yes") or
            (band == "large" and str(profile.get("size_large", "yes")) == "yes")
        );
        if not ok {
            return True;
        }
    }

    # Must-have: public/private
    if str(profile.get("control_importance", "ignore")) == "must" {
        want_pub = str(profile.get("want_public", "yes"));
        want_priv = str(profile.get("want_private", "yes"));
        ctrl = str(college.get("control", ""));
        is_pub = ctrl == "public";
        is_priv = ctrl in ["private_nonprofit", "private_forprofit"];
        if not ((is_pub and want_pub == "yes") or (is_priv and want_priv == "yes")) {
            return True;
        }
    }

    # Must-have: religious affiliation
    pref_rel = str(profile.get("religious", ""));
    if (str(profile.get("religious_importance", "ignore")) == "must" and pref_rel) {
        is_rel = bool(college.get("religiously_affiliated", False));
        if pref_rel == "religious" and not is_rel {
            return True;
        }
        if pref_rel == "secular" and is_rel {
            return True;
        }
    }

    # Must-have: max price
    max_price_raw = str(profile.get("max_price", ""));
    if (str(profile.get("price_importance", "ignore")) == "must"
            and max_price_raw.strip()) {
        max_price = _parse_f(max_price_raw);
        income = str(profile.get("income_bracket", ""));
        effective = _effective_price(college, income);
        if max_price is not None and effective is not None and effective > max_price {
            return True;
        }
    }

    return False;
}

# --- Bucket assignment ---

def _compute_bucket(college: any, profile: any) -> list[str] {
    admit_rate = college.get("admit_rate");

    if admit_rate is not None and float(admit_rate) < 0.15 {
        pct = round(float(admit_rate) * 100.0);
        return ["reach", f"Admit rate is {pct}% — always a Reach."];
    }

    test_plan = str(profile.get("test_plan", "none"));

    if test_plan == "sat" {
        sat_total = _parse_f(str(profile.get("sat_total", "")));
        r25 = college.get("sat_reading_p25");
        r75 = college.get("sat_reading_p75");
        m25 = college.get("sat_math_p25");
        m75 = college.get("sat_math_p75");
        if sat_total is not None and r25 is not None and m25 is not None {
            p25 = int(r25) + int(m25);
            p75 = int(r75 or r25) + int(m75 or m25);
            sat_str = f"{round(sat_total):,}";
            if sat_total < p25 {
                return ["reach", f"Your SAT {sat_str} is below their 25th percentile ({p25:,})."];
            }
            if sat_total >= p75 and (admit_rate is None or float(admit_rate) >= 0.5) {
                return ["likely", f"Your SAT {sat_str} is at or above their 75th percentile ({p75:,})."];
            }
            return ["target", f"Your SAT {sat_str} is within their middle 50% ({p25:,}–{p75:,})."];
        }
    }

    if test_plan == "act" {
        act = _parse_f(str(profile.get("act_composite", "")));
        a25 = college.get("act_p25");
        a75 = college.get("act_p75");
        if act is not None and a25 is not None {
            act_val = round(act);
            a75_val = int(a75 or a25);
            if act < int(a25) {
                return ["reach", f"Your ACT {act_val} is below their 25th percentile ({a25})."];
            }
            if act >= a75_val and (admit_rate is None or float(admit_rate) >= 0.5) {
                return ["likely", f"Your ACT {act_val} is at or above their 75th percentile ({a75_val})."];
            }
            return ["target", f"Your ACT {act_val} is within their middle 50% ({a25}–{a75_val})."];
        }
    }

    # Fall back to admit rate alone
    if admit_rate is None {
        return ["target", "No published admissions data — listed as a Target."];
    }
    rate = float(admit_rate);
    if rate >= 0.5 {
        return ["likely", f"Admit rate is {round(rate * 100)}% — typically a Likely."];
    }
    return ["target", f"Admit rate is {round(rate * 100)}%."];
}

# --- Fit scoring ---

def _compute_fit(college: any, profile: any, cip_prefixes: list[str],
                 home_coords: list[float] | None) -> list[any] {
    num = 0.0;
    denom = 0.0;
    reasons: list[str] = [];
    unit = str(college.get("unitid", ""));

    # Major availability
    undecided = str(profile.get("undecided", "no"));
    if undecided != "yes" and cip_prefixes {
        w = 20.0;
        denom = denom + w;
        if _college_offers(unit, cip_prefixes) {
            num = num + w;
            reasons.append("Offers your intended major.");
        } else {
            reasons.append("No exact major match in program data.");
        }
    }

    # Campus size
    w_size = _importance_weight(str(profile.get("size_importance", "ignore")));
    if w_size > 0.0 {
        denom = denom + w_size * 10.0;
        band = college.get("size_band");
        ok = (
            (band == "small" and str(profile.get("size_small", "yes")) == "yes") or
            (band == "medium" and str(profile.get("size_medium", "yes")) == "yes") or
            (band == "large" and str(profile.get("size_large", "yes")) == "yes")
        );
        if ok {
            num = num + w_size * 10.0;
            if band {
                reasons.append(f"{band.capitalize()} enrollment — matches your preference.");
            }
        }
    }

    # Region
    w_loc = _importance_weight(str(profile.get("location_importance", "ignore")));
    if w_loc > 0.0 {
        raw = str(profile.get("regions", ""));
        selected = [r for r in raw.split(",") if r.strip()];
        if selected {
            denom = denom + w_loc * 10.0;
            if str(college.get("region", "")) in selected {
                num = num + w_loc * 10.0;
                reasons.append(f"In your preferred region ({college.get('region')}).");
            }
        }
    }

    # Setting
    pref_set = str(profile.get("setting", ""));
    w_set = _importance_weight(str(profile.get("setting_importance", "ignore")));
    if w_set > 0.0 and pref_set {
        denom = denom + w_set * 8.0;
        if str(college.get("setting", "")) == pref_set {
            num = num + w_set * 8.0;
            reasons.append(f"{pref_set.capitalize()} setting — matches your preference.");
        }
    }

    # Distance
    w_dist = _importance_weight(str(profile.get("distance_importance", "ignore")));
    max_dist_raw = str(profile.get("distance", ""));
    if w_dist > 0.0 and max_dist_raw.strip() and home_coords is not None {
        max_dist = _parse_f(max_dist_raw);
        col_lat = college.get("latitude");
        col_lon = college.get("longitude");
        if max_dist is not None and col_lat is not None and col_lon is not None {
            denom = denom + w_dist * 8.0;
            d = _haversine(home_coords[0], home_coords[1], float(col_lat), float(col_lon));
            if d <= max_dist {
                num = num + w_dist * 8.0;
                reasons.append(f"{round(d)} mi from home — within your distance limit.");
            }
        }
    }

    # Public / private control
    w_ctrl = _importance_weight(str(profile.get("control_importance", "ignore")));
    if w_ctrl > 0.0 {
        denom = denom + w_ctrl * 8.0;
        ctrl = str(college.get("control", ""));
        is_pub = ctrl == "public";
        is_priv = ctrl in ["private_nonprofit", "private_forprofit"];
        if ((is_pub and str(profile.get("want_public", "yes")) == "yes") or
                (is_priv and str(profile.get("want_private", "yes")) == "yes")) {
            num = num + w_ctrl * 8.0;
        }
    }

    # Religious affiliation
    pref_rel = str(profile.get("religious", ""));
    w_rel = _importance_weight(str(profile.get("religious_importance", "ignore")));
    if w_rel > 0.0 and pref_rel {
        denom = denom + w_rel * 6.0;
        is_rel = bool(college.get("religiously_affiliated", False));
        if (pref_rel == "religious" and is_rel) or (pref_rel == "secular" and not is_rel) {
            num = num + w_rel * 6.0;
            if pref_rel == "religious" {
                reasons.append("Religiously affiliated — matches your preference.");
            }
        }
    }

    # HBCU boost
    w_hbcu = _importance_weight(str(profile.get("hbcu_importance", "ignore")));
    if w_hbcu > 0.0 and str(profile.get("want_hbcu", "no")) == "yes" {
        denom = denom + w_hbcu * 8.0;
        if college.get("hbcu") {
            num = num + w_hbcu * 8.0;
            reasons.append("HBCU — matches your preference.");
        }
    }

    # Women's college boost
    w_womens = _importance_weight(str(profile.get("womens_importance", "ignore")));
    if w_womens > 0.0 and str(profile.get("want_womens", "no")) == "yes" {
        denom = denom + w_womens * 8.0;
        if college.get("womens_college") {
            num = num + w_womens * 8.0;
            reasons.append("Women's college — matches your preference.");
        }
    }

    # Affordability
    w_price = _importance_weight(str(profile.get("price_importance", "ignore")));
    max_price_raw = str(profile.get("max_price", ""));
    income = str(profile.get("income_bracket", ""));
    if w_price > 0.0 {
        denom = denom + w_price * 15.0;
        max_price = _parse_f(max_price_raw);
        effective = _effective_price(college, income);
        if effective is not None {
            eff_f = float(effective);
            if max_price is not None {
                if eff_f <= max_price {
                    num = num + w_price * 15.0;
                    reasons.append(f"Net price ~${effective:,} — within your budget.");
                } elif eff_f <= max_price * 1.25 {
                    num = num + w_price * 7.0;
                }
            } elif eff_f < 20000.0 {
                num = num + w_price * 12.0;
                reasons.append(f"Low net price ~${effective:,}.");
            } elif eff_f < 35000.0 {
                num = num + w_price * 8.0;
            } else {
                num = num + w_price * 3.0;
            }
        }
    }

    # Outcomes (graduation rate + earnings)
    w_out = _importance_weight(str(profile.get("outcomes_importance", "ignore")));
    if w_out > 0.0 {
        denom = denom + w_out * 12.0;
        grad = college.get("grad_rate_6yr");
        earn = college.get("earnings_10yr");
        out_score = 0.0;
        if grad is not None {
            out_score = out_score + min(float(grad), 1.0) * 0.5;
        } else {
            out_score = out_score + 0.3;
        }
        if earn is not None {
            earn_f = float(earn);
            if earn_f >= 60000.0 {
                out_score = out_score + 0.5;
                reasons.append(f"Strong outcomes: ~${earn:,} median 10-yr earnings.");
            } elif earn_f >= 45000.0 {
                out_score = out_score + 0.35;
            } else {
                out_score = out_score + 0.15;
            }
        } else {
            out_score = out_score + 0.25;
        }
        num = num + w_out * 12.0 * min(out_score, 1.0);
    }

    if denom <= 0.0 {
        return [50, reasons];
    }
    score = int(round(num / denom * 100.0));
    return [score, reasons];
}

# --- Public endpoint ---

def:pub match_colleges(profile: any) -> MatchResponse {
    # Resolve home ZIP to lat/lon for distance filtering and scoring
    home_zip = str(profile.get("home_zip", "")).strip().zfill(5)[:5];
    home_coords: list[float] | None = _zip_coords.get(home_zip);

    # Resolve desired major names to CIP prefixes
    undecided = str(profile.get("undecided", "no"));
    major_names: list[str] = [];
    if undecided != "yes" {
        for key in ["major1", "major2", "major3"] {
            n = str(profile.get(key, "")).strip();
            if n {
                major_names.append(n);
            }
        }
    }
    cip_prefixes = _major_cip_prefixes(major_names);

    reach: list[MatchResult] = [];
    target: list[MatchResult] = [];
    likely: list[MatchResult] = [];
    filtered = 0;

    for college in _colleges {
        # Require at least one bachelor's program
        if int(college.get("bachelor_program_count", 0) or 0) == 0 {
            filtered = filtered + 1;
            continue;
        }

        if _should_filter(college, profile, home_coords) {
            filtered = filtered + 1;
            continue;
        }

        bucket_pair = _compute_bucket(college, profile);
        bucket = str(bucket_pair[0]);
        reason = str(bucket_pair[1]);

        fit_pair = _compute_fit(college, profile, cip_prefixes, home_coords);
        fit_score = int(fit_pair[0]);
        fit_reasons = fit_pair[1] as list[str];

        income = str(profile.get("income_bracket", ""));
        price_bracket = _effective_price(college, income);

        r25 = college.get("sat_reading_p25");
        m25 = college.get("sat_math_p25");
        r75 = college.get("sat_reading_p75");
        m75 = college.get("sat_math_p75");
        sat_p25: int | None = None;
        sat_p75: int | None = None;
        if r25 is not None and m25 is not None {
            sat_p25 = int(r25) + int(m25);
        }
        if r75 is not None and m75 is not None {
            sat_p75 = int(r75) + int(m75);
        }

        result = MatchResult(
            unitid=str(college.get("unitid", "")),
            name=str(college.get("name", "")),
            city=str(college.get("city", "")),
            state=str(college.get("state", "")),
            bucket=bucket,
            fit_score=fit_score,
            website=str(college.get("website") or ""),
            admit_rate=college.get("admit_rate"),
            sat_composite_p25=sat_p25,
            sat_composite_p75=sat_p75,
            act_p25=college.get("act_p25"),
            act_p75=college.get("act_p75"),
            net_price_for_bracket=price_bracket,
            net_price=college.get("net_price"),
            grad_rate_6yr=college.get("grad_rate_6yr"),
            earnings_10yr=college.get("earnings_10yr"),
            size_band=str(college.get("size_band") or ""),
            setting=str(college.get("setting") or ""),
            control=str(college.get("control") or ""),
            hbcu=bool(college.get("hbcu", False)),
            womens_college=bool(college.get("womens_college", False)),
            bucket_reason=reason,
            fit_reasons=fit_reasons
        );

        if bucket == "reach" {
            reach.append(result);
        } elif bucket == "likely" {
            likely.append(result);
        } else {
            target.append(result);
        }
    }

    # Sort by fit score descending; cap at 30 per bucket
    reach.sort(key=lambda (r: MatchResult) { return -r.fit_score; });
    target.sort(key=lambda (r: MatchResult) { return -r.fit_score; });
    likely.sort(key=lambda (r: MatchResult) { return -r.fit_score; });

    cap = 30;
    if len(reach) > cap {
        reach = reach[:cap];
    }
    if len(target) > cap {
        target = target[:cap];
    }
    if len(likely) > cap {
        likely = likely[:cap];
    }

    return MatchResponse(
        reach=reach,
        target=target,
        likely=likely,
        total_filtered=filtered
    );
}


# Fields from colleges.jsonl safe to send to the detail page.
glob _DETAIL_FIELDS: list[str] = [
    "unitid", "name", "city", "state", "region", "setting", "control", "website",
    "hbcu", "womens_college", "religiously_affiliated", "open_admission",
    "undergrad_enrollment", "size_band", "applicants", "admitted", "admit_rate",
    "yield_rate", "sat_reading_p25", "sat_reading_p75", "sat_math_p25", "sat_math_p75",
    "act_p25", "act_p75", "sat_submit_rate", "act_submit_rate", "test_policy",
    "tuition_in_state", "fees_in_state", "tuition_out_of_state", "fees_out_of_state",
    "room_and_board", "application_fee", "net_price", "net_price_0_30k",
    "net_price_30_48k", "net_price_48_75k", "net_price_75_110k", "net_price_110k_plus",
    "grad_rate_4yr", "grad_rate_6yr", "retention_rate", "earnings_6yr", "earnings_10yr",
    "median_debt", "pell_share", "first_gen_share", "latitude", "longitude"
];

def:pub college_detail(unitid: str, profile: any) -> CollegeDetail {
    college = _college_index.get(str(unitid));
    if college is None {
        return CollegeDetail();
    }
    home_zip = str(profile.get("home_zip", "")).strip().zfill(5)[:5];
    home_coords: list[float] | None = _zip_coords.get(home_zip);

    major_names: list[str] = [];
    if str(profile.get("undecided", "no")) != "yes" {
        for key in ["major1", "major2", "major3"] {
            n = str(profile.get(key, "")).strip();
            if n {
                major_names.append(n);
            }
        }
    }
    cip_prefixes = _major_cip_prefixes(major_names);

    bucket_pair = _compute_bucket(college, profile);
    fit_pair = _compute_fit(college, profile, cip_prefixes, home_coords);

    slim: dict[str, any] = {};
    for key in _DETAIL_FIELDS {
        slim[key] = college.get(key);
    }

    cds_row = _cds_index.get(str(unitid));
    cds: dict[str, any] = {};
    if cds_row is not None {
        for key in ["cds_year", "archive_url", "gpa_average", "gpa_pct", "ed_offered",
                    "ed_admit_rate", "ea_offered", "ea_restrictive", "in_state_admit_rate",
                    "out_of_state_admit_rate", "sat_composite_p25", "sat_composite_p50",
                    "sat_composite_p75", "gpa_importance", "test_importance"] {
            cds[key] = cds_row.get(key);
        }
    }

    dist: int | None = None;
    lat = college.get("latitude");
    lon = college.get("longitude");
    if home_coords is not None and lat is not None and lon is not None {
        dist = int(round(_haversine(home_coords[0], home_coords[1], float(lat), float(lon))));
    }

    return CollegeDetail(
        found=True,
        college=slim,
        cds=cds,
        bucket=str(bucket_pair[0]),
        bucket_reason=str(bucket_pair[1]),
        fit_score=int(fit_pair[0]),
        fit_reasons=fit_pair[1] as list[str],
        price=_effective_price(college, str(profile.get("income_bracket", ""))),
        distance_miles=dist,
        program_count=len(_programs_index.get(str(unitid), []))
    );
}
