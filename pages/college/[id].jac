"""College detail page: stats, where the student stands, and the fit breakdown."""

import from "@jac/runtime" { Link, useParams }
import from ...format { fmt_rate, fmt_price, fmt_num, fmt_int, fmt_sat, fmt_act }
import from ...matcher { college_detail, CollegeDetail }
import from ...theme {
    Shell,
    DETAIL_PAGE,
    DETAIL_GRID,
    DETAIL_CARD,
    DETAIL_HEAD,
    STAT_ROW,
    STAT_LABEL,
    STAT_VALUE,
    RANGE_TRACK,
    BADGE_ROW,
    NOTE_TEXT,
    FIT_BADGE,
    BUCKET_LABEL_REACH,
    BUCKET_LABEL_TARGET,
    BUCKET_LABEL_LIKELY,
    REASONS_LIST,
    EYEBROW,
    TITLE,
    LEDE,
    BANNER,
    DISCLAIMER,
    LOADING_BOX,
    SECONDARY,
    range_fill,
    range_marker
}

def Row(label: str, value: str) -> JsxElement {
    <div style={STAT_ROW}>
        <span style={STAT_LABEL}>{label}</span>
        <span style={STAT_VALUE}>{value}</span>
    </div>
}

def label_control(control: str) -> str {
    if control == "public" {
        return "Public";
    }
    if control == "private_nonprofit" {
        return "Private nonprofit";
    }
    if control == "private_forprofit" {
        return "Private for-profit";
    }
    return "—";
}

def cap(text: str) -> str {
    if not text {
        return "—";
    }
    return text[0].upper() + text[1:];
}

def pct_on_scale(value: float, lo: float, hi: float) -> float {
    if hi <= lo {
        return 50.0;
    }
    p = (value - lo) / (hi - lo) * 100.0;
    return max(0.0, min(100.0, p));
}

def yes_no(flag: bool) -> str {
    return "Yes" if flag else "No";
}

def:pub CollegePage -> JsxPage {
    has detail: CollegeDetail | None = None,
        loading: bool = True,
        error: str = "",
        profile: any = None;

    params = useParams();

    async can with entry {
        uid = params["id"];
        if not uid {
            error = "No college selected.";
            loading = False;
            return;
        }
        prof: any = {};
        try {
            raw = localStorage.getItem("jaccepted.intake");
            if raw {
                prof = JSON.parse(raw);
            }
        } except Exception {
            prof = {};
        }
        profile = prof;
        try {
            data = await college_detail(uid, prof);
            if not data.found {
                error = "We couldn't find that college.";
            } else {
                detail = data;
            }
        } except Exception as e {
            error = str(e);
        }
        loading = False;
    }

    <Shell>
        <div style={DETAIL_PAGE}>
            <div style={{"marginBottom": "1rem"}}>
                <Link to="/results" style={SECONDARY}>← Back to results</Link>
            </div>
            {if loading {
                <div style={LOADING_BOX}><p>Loading college…</p></div>
            } elif error {
                <div style={BANNER} role="alert">{error}</div>
            } elif detail is not None {
                <CollegeBody detail={detail} profile={profile} />
            }}
        </div>
    </Shell>
}

def CollegeBody(detail: CollegeDetail, profile: any) -> JsxElement {
    c = detail.college;
    cds = detail.cds;

    bucket = detail.bucket;
    bucket_style = BUCKET_LABEL_TARGET;
    if bucket == "reach" {
        bucket_style = BUCKET_LABEL_REACH;
    } elif bucket == "likely" {
        bucket_style = BUCKET_LABEL_LIKELY;
    }

    sat_p25: int | None = None;
    sat_p75: int | None = None;
    if c["sat_reading_p25"] is not None and c["sat_math_p25"] is not None {
        sat_p25 = int(c["sat_reading_p25"]) + int(c["sat_math_p25"]);
    }
    if c["sat_reading_p75"] is not None and c["sat_math_p75"] is not None {
        sat_p75 = int(c["sat_reading_p75"]) + int(c["sat_math_p75"]);
    }
    sat_text = fmt_sat(sat_p25, sat_p75);
    act_text = fmt_act(c["act_p25"], c["act_p75"]);

    your_sat = 0.0;
    has_sat = False;
    if profile and profile["test_plan"] == "sat" and profile["sat_total"] {
        your_sat = float(profile["sat_total"]);
        has_sat = your_sat > 0.0;
    }
    your_gpa = "";
    if profile and profile["gpa_unweighted"] {
        your_gpa = str(profile["gpa_unweighted"]);
    }

    scale_lo = 400.0;
    scale_hi = 1600.0;
    if sat_p25 is not None and sat_p75 is not None {
        scale_lo = max(400.0, float(sat_p25) - 250.0);
        scale_hi = min(1600.0, float(sat_p75) + 250.0);
    }

    location = str(c["city"]) + ", " + str(c["state"]);
    website = str(c["website"] or "");
    site_href = website;
    if website and not website.startswith("http") {
        site_href = "https://" + website;
    }

    badges: list[str] = [];
    if c["hbcu"] {
        badges.append("HBCU");
    }
    if c["womens_college"] {
        badges.append("Women's college");
    }
    if c["religiously_affiliated"] {
        badges.append("Religiously affiliated");
    }
    if c["open_admission"] {
        badges.append("Open admission");
    }

    <div>
        <header>
            <p style={EYEBROW}>{label_control(str(c["control"]))}</p>
            <h1 style={TITLE}>{c["name"]}</h1>
            <p style={LEDE}>{location}{detail.distance_miles is not None and " · " + str(detail.distance_miles) + " mi from home"}</p>
            <div style={BADGE_ROW}>
                <span style={bucket_style}>{cap(bucket)}</span>
                <span style={FIT_BADGE}>Fit {detail.fit_score}/100</span>
                {for b in badges {
                    <span key={b} style={FIT_BADGE}>{b}</span>
                }}
                {site_href and <a href={site_href} target="_blank" rel="noreferrer">Visit website ↗</a>}
            </div>
        </header>

        <p style={DISCLAIMER}>
            Reach / Target / Likely is an estimate from public data, not an admission decision.
        </p>

        <div style={DETAIL_GRID}>
            <section style={DETAIL_CARD}>
                <h2 style={DETAIL_HEAD}>Where you stand</h2>
                <p style={{"margin": "0"}}>{detail.bucket_reason}</p>
                {sat_p25 is not None and sat_p75 is not None and
                    <div>
                        <div style={RANGE_TRACK}>
                            <div style={range_fill(
                                pct_on_scale(float(sat_p25), scale_lo, scale_hi),
                                pct_on_scale(float(sat_p75), scale_lo, scale_hi)
                            )}></div>
                            {has_sat and <div style={range_marker(pct_on_scale(your_sat, scale_lo, scale_hi))}></div>}
                        </div>
                        <div style={STAT_ROW}>
                            <span style={STAT_LABEL}>Middle 50% SAT</span>
                            <span style={STAT_VALUE}>{sat_text}</span>
                        </div>
                        {has_sat and <Row label="Your SAT" value={fmt_int(round(your_sat))} />}
                        <p style={NOTE_TEXT}>Green bar = middle 50% of admitted students. Red tick = you.</p>
                    </div>
                }
                {sat_p25 is None and act_text and <Row label="Middle 50% ACT" value={act_text} />}
                {cds["gpa_average"] is not None and <Row label="Average GPA of admitted" value={str(cds["gpa_average"])} />}
                {your_gpa and <Row label="Your unweighted GPA" value={your_gpa} />}
                <Row label="Admit rate" value={fmt_rate(c["admit_rate"])} />
                {sat_p25 is None and not act_text and <p style={NOTE_TEXT}>This school doesn't publish test score ranges.</p>}
            </section>

            <section style={DETAIL_CARD}>
                <h2 style={DETAIL_HEAD}>Why it fits you</h2>
                {if len(detail.fit_reasons) == 0 {
                    <p style={NOTE_TEXT}>No specific preference matches to show.</p>
                } else {
                    <ul style={REASONS_LIST}>
                        {for r in detail.fit_reasons {
                            <li key={r}>{r}</li>
                        }}
                    </ul>
                }}
                <p style={NOTE_TEXT}>Fit score reflects how well the school matches the preferences you rated in intake.</p>
            </section>

            <section style={DETAIL_CARD}>
                <h2 style={DETAIL_HEAD}>Admissions</h2>
                <Row label="Applicants" value={fmt_num(c["applicants"])} />
                <Row label="Admitted" value={fmt_num(c["admitted"])} />
                <Row label="Yield (admitted who enroll)" value={fmt_rate(c["yield_rate"])} />
                <Row label="Submitted SAT" value={fmt_rate(c["sat_submit_rate"])} />
                <Row label="Submitted ACT" value={fmt_rate(c["act_submit_rate"])} />
                {cds["ed_offered"] is not None and <Row label="Early Decision" value={yes_no(bool(cds["ed_offered"]))} />}
                {cds["ed_admit_rate"] is not None and <Row label="ED admit rate" value={fmt_rate(cds["ed_admit_rate"])} />}
                {cds["ea_offered"] is not None and <Row label="Early Action" value={yes_no(bool(cds["ea_offered"]))} />}
                {cds["in_state_admit_rate"] is not None and <Row label="In-state admit rate" value={fmt_rate(cds["in_state_admit_rate"])} />}
                {cds["out_of_state_admit_rate"] is not None and <Row label="Out-of-state admit rate" value={fmt_rate(cds["out_of_state_admit_rate"])} />}
                <Row label="Application fee" value={fmt_price(c["application_fee"])} />
            </section>

            <section style={DETAIL_CARD}>
                <h2 style={DETAIL_HEAD}>Cost</h2>
                <Row label="Estimated net price" value={fmt_price(detail.price)} />
                <Row label="Tuition (in-state)" value={fmt_price(c["tuition_in_state"])} />
                <Row label="Tuition (out-of-state)" value={fmt_price(c["tuition_out_of_state"])} />
                <Row label="Room & board" value={fmt_price(c["room_and_board"])} />
                <Row label="Net price: income $0–30k" value={fmt_price(c["net_price_0_30k"])} />
                <Row label="Net price: $30–48k" value={fmt_price(c["net_price_30_48k"])} />
                <Row label="Net price: $48–75k" value={fmt_price(c["net_price_48_75k"])} />
                <Row label="Net price: $75–110k" value={fmt_price(c["net_price_75_110k"])} />
                <Row label="Net price: $110k+" value={fmt_price(c["net_price_110k_plus"])} />
                <p style={NOTE_TEXT}>
                    Net price is what families pay after grants (2022-23 data). If you didn't enter an income
                    bracket, this is the school's overall average, or the mean of its income brackets.
                </p>
            </section>

            <section style={DETAIL_CARD}>
                <h2 style={DETAIL_HEAD}>Outcomes</h2>
                <Row label="4-year graduation rate" value={fmt_rate(c["grad_rate_4yr"])} />
                <Row label="6-year graduation rate" value={fmt_rate(c["grad_rate_6yr"])} />
                <Row label="First-year retention" value={fmt_rate(c["retention_rate"])} />
                <Row label="Median earnings, 6 yrs out" value={fmt_price(c["earnings_6yr"])} />
                <Row label="Median earnings, 10 yrs out" value={fmt_price(c["earnings_10yr"])} />
                <Row label="Median debt at graduation" value={fmt_price(c["median_debt"])} />
                <Row label="Students receiving Pell grants" value={fmt_rate(c["pell_share"])} />
                <Row label="First-generation students" value={fmt_rate(c["first_gen_share"])} />
            </section>

            <section style={DETAIL_CARD}>
                <h2 style={DETAIL_HEAD}>Campus</h2>
                <Row label="Undergraduates" value={fmt_num(c["undergrad_enrollment"])} />
                <Row label="Size" value={cap(str(c["size_band"] or ""))} />
                <Row label="Setting" value={cap(str(c["setting"] or ""))} />
                <Row label="Region" value={str(c["region"] or "—")} />
                <Row label="Bachelor's programs" value={str(detail.program_count)} />
            </section>
        </div>
        <p style={NOTE_TEXT}>
            Data: IPEDS and College Scorecard (U.S. Department of Education){cds["cds_year"] and ", Common Data Set " + str(cds["cds_year"])}.
            Figures are a year or more old; check the school's website for current numbers.
        </p>
    </div>
}
