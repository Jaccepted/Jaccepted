"""One college in detail: stats, where the student stands, and why it fits.

Reads the intake profile saved in this browser, asks the server to score this
college the same way the results list does, and lays out the public data.
"""

import from "@jac/runtime" { Link, useParams }
import from .matching { CollegeDetail, Profile, college_detail }
import from .results { dollars, profile_from }
import from .list_store { refresh_saved }
import from .components.nav { TopNav }
import from .theme {
    BANNER,
    BADGE,
    CARD,
    DETAIL_GRID,
    EYEBROW,
    FACTS,
    FIT,
    HINT,
    LEDE,
    LINK,
    PAGE,
    REASONS,
    SECTION_TITLE,
    STACK,
    STAT_LABEL,
    STAT_ROW,
    STAT_VALUE,
    TITLE,
    RANGE_TRACK,
    bucket_look,
    range_fill,
    range_marker
}

def grouped(amount: int) -> str {
    digits = str(amount);
    out = "";
    while len(digits) > 3 {
        out = "," + digits[len(digits) - 3:] + out;
        digits = digits[:len(digits) - 3];
    }
    return digits + out;
}

def count_text(value: int | None) -> str {
    if value is None {
        return "—";
    }
    return grouped(int(value));
}

def money_text(value: int | None) -> str {
    if value is None {
        return "—";
    }
    return dollars(int(value));
}

def rate_text(value: float | None) -> str {
    if value is None {
        return "—";
    }
    return str(Math.round(value * 100)) + "%";
}

def control_text(control: str) -> str {
    if control == "public" {
        return "Public";
    }
    if control == "private_nonprofit" {
        return "Private nonprofit";
    }
    if control == "private_forprofit" {
        return "Private for-profit";
    }
    return "College";
}

def title_case(text: str | None) -> str {
    if not text {
        return "—";
    }
    return text[0].upper() + text[1:];
}

def place_on(value: float, low: float, high: float) -> float {
    if high <= low {
        return 50.0;
    }
    return Math.max(0.0, Math.min(100.0, (value - low) / (high - low) * 100.0));
}

def Row(label: str, value: str) -> JsxElement {
    <div style={STAT_ROW}>
        <span style={STAT_LABEL}>{label}</span>
        <span style={STAT_VALUE}>{value}</span>
    </div>
}

def Standing(detail: CollegeDetail, profile: Profile) -> JsxElement {
    c = detail.college;
    cds = detail.cds;
    low: int | None = None;
    high: int | None = None;
    # Same order the matcher uses for the sentence above: Common Data Set first.
    if cds["sat_composite_p25"] is not None and cds["sat_composite_p75"] is not None {
        low = int(cds["sat_composite_p25"]);
        high = int(cds["sat_composite_p75"]);
    } elif c["sat_reading_p25"] is not None and c["sat_math_p25"] is not None {
        low = int(c["sat_reading_p25"]) + int(c["sat_math_p25"]);
        high = int(c["sat_reading_p75"]) + int(c["sat_math_p75"]);
    }
    act_low = c["act_p25"] if c["act_p25"] is not None else cds["act_p25"];
    act_high = c["act_p75"] if c["act_p75"] is not None else cds["act_p75"];

    yours = 0.0;
    if profile.test_plan == "sat" and profile.sat_total {
        yours = parseFloat(profile.sat_total);
    }
    has_yours = yours > 0.0;

    lo_end = 400.0;
    hi_end = 1600.0;
    if low is not None and high is not None {
        lo_end = Math.max(400.0, low - 250.0);
        hi_end = Math.min(1600.0, high + 250.0);
    }

    <section style={CARD} aria-labelledby="standing-title">
        <h2 id="standing-title" style={SECTION_TITLE}>Where you stand</h2>
        <p style={{"margin": "0"}}>{detail.reasons[0]}</p>
        {if low is not None and high is not None {
            <div>
                <div style={RANGE_TRACK} role="img" aria-label={"Middle 50% SAT " + grouped(low) + " to " + grouped(high)}>
                    <div style={range_fill(place_on(low, lo_end, hi_end), place_on(high, lo_end, hi_end))}></div>
                    {has_yours and <div style={range_marker(place_on(yours, lo_end, hi_end))}></div>}
                </div>
                <Row label="Middle 50% SAT" value={grouped(low) + "–" + grouped(high)} />
                {has_yours and <Row label="Your SAT" value={grouped(int(yours))} />}
                <p style={HINT}>Green bar: middle 50% of admitted students. Red tick: you.</p>
            </div>
        } elif act_low is not None and act_high is not None {
            <Row label="Middle 50% ACT" value={str(act_low) + "–" + str(act_high)} />
        } else {
            <p style={HINT}>This college does not publish test score ranges.</p>
        }}
        {cds["gpa_average"] is not None and <Row label="Average GPA of admitted students" value={str(cds["gpa_average"])} />}
        {profile.gpa_unweighted and <Row label="Your unweighted GPA" value={profile.gpa_unweighted} />}
        <Row label="Admit rate" value={rate_text(c["admit_rate"])} />
    </section>
}

def CollegeBody(detail: CollegeDetail, profile: Profile) -> JsxElement {
    c = detail.college;
    cds = detail.cds;
    flags: list[str] = [];
    if c["hbcu"] {
        flags.append("HBCU");
    }
    if c["womens_college"] {
        flags.append("Women's college");
    }
    if c["religiously_affiliated"] {
        flags.append("Religiously affiliated");
    }
    if c["open_admission"] {
        flags.append("Open admission");
    }
    site = str(c["website"] or "");
    if site and not site.startswith("http") {
        site = "https://" + site;
    }
    where = str(c["city"] or "") + ", " + str(c["state"] or "");
    if detail.miles is not None {
        where = where + " · " + grouped(int(detail.miles)) + " miles from home";
    }

    <div style={STACK}>
        <header>
            <p style={EYEBROW}>{control_text(str(c["control"]))}</p>
            <h1 style={TITLE}>{c["name"]}</h1>
            <p style={LEDE}>{where}</p>
            <p style={FACTS}>
                <span style={bucket_look(detail.bucket)}>{title_case(detail.bucket)}</span>
                <span style={FIT} aria-label={"Fit " + str(detail.fit) + " out of 100"}>{detail.fit}</span>
                {for flag in flags {
                    <span key={flag} style={BADGE}>{flag}</span>
                }}
                {site and <a style={LINK} href={site} target="_blank" rel="noreferrer">Visit website ↗</a>}
            </p>
            <p style={HINT}>Reach, Target and Likely are estimates from public data, not admission predictions.</p>
        </header>

        <div style={DETAIL_GRID}>
            <Standing detail={detail} profile={profile} />

            <section style={CARD} aria-labelledby="fit-title">
                <h2 id="fit-title" style={SECTION_TITLE}>Why it fits you</h2>
                <ul style={REASONS}>
                    {for reason in detail.reasons[1:] {
                        <li key={reason}>{reason}</li>
                    }}
                </ul>
                <p style={HINT}>The fit score reflects the preferences you rated in your profile.</p>
            </section>

            <section style={CARD} aria-labelledby="admissions-title">
                <h2 id="admissions-title" style={SECTION_TITLE}>Admissions</h2>
                <Row label="Applicants" value={count_text(c["applicants"])} />
                <Row label="Admitted" value={count_text(c["admitted"])} />
                <Row label="Admitted who enroll" value={rate_text(c["yield_rate"])} />
                <Row label="Submitted SAT" value={rate_text(c["sat_submit_rate"])} />
                <Row label="Submitted ACT" value={rate_text(c["act_submit_rate"])} />
                {cds["ed_offered"] is not None and <Row label="Early Decision" value={"Yes" if cds["ed_offered"] else "No"} />}
                {cds["ed_admit_rate"] is not None and <Row label="Early Decision admit rate" value={rate_text(cds["ed_admit_rate"])} />}
                {cds["ea_offered"] is not None and <Row label="Early Action" value={"Yes" if cds["ea_offered"] else "No"} />}
                {cds["in_state_admit_rate"] is not None and <Row label="In-state admit rate" value={rate_text(cds["in_state_admit_rate"])} />}
                {cds["out_of_state_admit_rate"] is not None and <Row label="Out-of-state admit rate" value={rate_text(cds["out_of_state_admit_rate"])} />}
                <Row label="Application fee" value={money_text(c["application_fee"])} />
            </section>

            <section style={CARD} aria-labelledby="cost-title">
                <h2 id="cost-title" style={SECTION_TITLE}>Cost</h2>
                <Row label="Estimated net price per year" value={money_text(detail.net_price)} />
                <Row label="Tuition, in-state" value={money_text(c["tuition_in_state"])} />
                <Row label="Tuition, out-of-state" value={money_text(c["tuition_out_of_state"])} />
                <Row label="Room and board" value={money_text(c["room_and_board"])} />
                <Row label="Net price, income under $30k" value={money_text(c["net_price_0_30k"])} />
                <Row label="Net price, $30–48k" value={money_text(c["net_price_30_48k"])} />
                <Row label="Net price, $48–75k" value={money_text(c["net_price_48_75k"])} />
                <Row label="Net price, $75–110k" value={money_text(c["net_price_75_110k"])} />
                <Row label="Net price, $110k and up" value={money_text(c["net_price_110k_plus"])} />
                <p style={HINT}>
                    Net price is the cost after grants (2022-23 data). Without an income bracket in your profile, this uses the college's overall average, or the mean of its bracket prices.
                </p>
            </section>

            <section style={CARD} aria-labelledby="outcomes-title">
                <h2 id="outcomes-title" style={SECTION_TITLE}>Outcomes</h2>
                <Row label="Graduate in four years" value={rate_text(c["grad_rate_4yr"])} />
                <Row label="Graduate in six years" value={rate_text(c["grad_rate_6yr"])} />
                <Row label="First-year retention" value={rate_text(c["retention_rate"])} />
                <Row label="Median earnings, 6 years out" value={money_text(c["earnings_6yr"])} />
                <Row label="Median earnings, 10 years out" value={money_text(c["earnings_10yr"])} />
                <Row label="Median debt at graduation" value={money_text(c["median_debt"])} />
                <Row label="Students with Pell grants" value={rate_text(c["pell_share"])} />
                <Row label="First-generation students" value={rate_text(c["first_gen_share"])} />
            </section>

            <section style={CARD} aria-labelledby="campus-title">
                <h2 id="campus-title" style={SECTION_TITLE}>Campus</h2>
                <Row label="Undergraduates" value={count_text(c["undergrad_enrollment"])} />
                <Row label="Size" value={title_case(c["size_band"])} />
                <Row label="Setting" value={title_case(c["setting"])} />
                <Row label="Region" value={str(c["region"] or "—")} />
                <Row label="Bachelor's programs" value={str(detail.program_count)} />
            </section>
        </div>
        <p style={HINT}>
            Data: IPEDS and College Scorecard (U.S. Department of Education){cds["cds_year"] and ", Common Data Set " + str(cds["cds_year"])}. Figures are a year or more old, so check the college's website for current numbers.
        </p>
    </div>
}

def:pub CollegeView -> JsxElement {
    has status: str = "loading",
        message: str = "",
        detail: CollegeDetail | None = None,
        profile: Profile = Profile(),
        saved_count: int = 0;

    params = useParams();

    async def load -> None {
        saved_items = await refresh_saved();
        saved_count = len(saved_items);
        unitid = params["id"];
        if not unitid {
            message = "No college selected.";
            status = "error";
            return;
        }
        raw = None;
        try {
            raw = localStorage.getItem("jaccepted.intake");
        } except Exception {
            raw = None;
        }
        if raw {
            try {
                profile = profile_from(JSON.parse(raw));
            } except Exception {
                profile = Profile();
            }
        }
        try {
            found = await college_detail(str(unitid), profile);
            if found.found {
                detail = found;
                status = "ready";
            } else {
                message = "We could not find that college.";
                status = "error";
            }
        } except Exception as err {
            message = str(err);
            status = "error";
        }
    }

    can with entry {
        load();
    }

    <>
        <TopNav current="" saved_count={saved_count} />
        <div style={PAGE}>
            <p><Link style={LINK} to="/results">← Back to results</Link></p>
            {if status == "loading" {
                <p style={HINT} role="status">Loading college…</p>
            }}
            {if status == "error" {
                <p style={BANNER} role="alert">{message}</p>
            }}
            {if status == "ready" and detail {
                <CollegeBody detail={detail} profile={profile} />
            }}
        </div>
    </>
}
