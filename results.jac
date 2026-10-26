"""College list results.

Reads the intake profile saved in this browser, runs matching on the server,
and shows Reach, Target, and Likely colleges with the reasons for each.
"""

import from "@jac/runtime" { Link }
import from .matching { CollegeMatch, MatchResult, Profile, match_colleges }
import from .list_store { refresh_dismissed, refresh_saved, store_dismissed, store_saved }
import from .components.nav { TopNav }
import from .theme {
    BADGE,
    BANNER,
    BUCKET_HEAD,
    CARD,
    EYEBROW,
    FACTS,
    FIT,
    HINT,
    LEDE,
    LINK,
    LINK_BUTTON,
    NAV,
    PAGE,
    PRIMARY,
    SECONDARY,
    REASONS,
    RESULT,
    RESULT_HEAD,
    RESULT_NAME,
    STACK,
    TITLE,
    bucket_look
}

def saved(data: any, key: str, fallback: str) -> str {
    value = data[key];
    if value {
        return value as str;
    }
    return fallback;
}

def:pub profile_from(data: any) -> Profile {
    return Profile(
        gpa_unweighted=saved(data, "gpa_unweighted", ""),
        gpa_scale=saved(data, "gpa_scale", "4.0"),
        test_plan=saved(data, "test_plan", "none"),
        sat_total=saved(data, "sat_total", ""),
        act_composite=saved(data, "act_composite", ""),
        undecided=saved(data, "undecided", "no"),
        major1=saved(data, "major1", ""),
        major2=saved(data, "major2", ""),
        major3=saved(data, "major3", ""),
        regions=saved(data, "regions", ""),
        location_importance=saved(data, "location_importance", "ignore"),
        setting=saved(data, "setting", ""),
        setting_importance=saved(data, "setting_importance", "ignore"),
        distance=saved(data, "distance", ""),
        distance_importance=saved(data, "distance_importance", "ignore"),
        size_small=saved(data, "size_small", "yes"),
        size_medium=saved(data, "size_medium", "yes"),
        size_large=saved(data, "size_large", "yes"),
        size_importance=saved(data, "size_importance", "ignore"),
        want_public=saved(data, "want_public", "yes"),
        want_private=saved(data, "want_private", "yes"),
        control_importance=saved(data, "control_importance", "ignore"),
        religious=saved(data, "religious", ""),
        religious_importance=saved(data, "religious_importance", "ignore"),
        want_hbcu=saved(data, "want_hbcu", "no"),
        hbcu_importance=saved(data, "hbcu_importance", "ignore"),
        want_womens=saved(data, "want_womens", "no"),
        womens_importance=saved(data, "womens_importance", "ignore"),
        max_price=saved(data, "max_price", ""),
        price_importance=saved(data, "price_importance", "ignore"),
        outcomes_importance=saved(data, "outcomes_importance", "ignore"),
        income_bracket=saved(data, "income_bracket", ""),
        home_state=saved(data, "home_state", ""),
        home_zip=saved(data, "home_zip", "")
    );
}

def admit_text(rate: float | None) -> str {
    if rate is None {
        return "Admit rate not published";
    }
    return "Admits " + str(Math.round(rate * 100)) + "%";
}

def price_text(price: int | None) -> str {
    if price is None {
        return "Net price not published";
    }
    return "~" + dollars(price) + "/yr net";
}

def:pub dollars(amount: int) -> str {
    digits = str(amount);
    grouped = "";
    while len(digits) > 3 {
        grouped = "," + digits[len(digits) - 3:] + grouped;
        digits = digits[:len(digits) - 3];
    }
    return "$" + digits + grouped;
}

def ResultCard(
    item: CollegeMatch,
    saved: bool,
    onSave: Callable[[CollegeMatch], None],
    onDismiss: Callable[[CollegeMatch], None]
) -> JsxElement {
    <li style={RESULT}>
        <div style={RESULT_HEAD}>
            <div>
                <h3 style={RESULT_NAME}>
                    <Link style={LINK} to={"/college/" + item.unitid}>{item.name}</Link>
                    {item.shortlist and <span style={BADGE}>Shortlist</span>}
                </h3>
                <p style={FACTS}>
                    <span>{item.city + ", " + item.state}</span>
                    <span>{admit_text(item.admit_rate)}</span>
                    <span>{price_text(item.net_price)}</span>
                </p>
            </div>
            <div style={FIT} aria-label={"Fit " + str(item.fit) + " out of 100"}>{item.fit}</div>
        </div>
        <ul style={REASONS}>
            {for reason in item.reasons {
                <li key={reason}>{reason}</li>
            }}
        </ul>
        <div style={NAV}>
            {if saved {
                <button type="button" style={SECONDARY} onClick={lambda { onSave(item); }}>Saved ✓ (remove)</button>
            } else {
                <button type="button" style={PRIMARY} onClick={lambda { onSave(item); }}>Save to My List</button>
            }}
            <button type="button" style={SECONDARY} onClick={lambda { onDismiss(item); }}>Not interested</button>
        </div>
    </li>
}

def Bucket(
    bucket: str,
    title: str,
    blurb: str,
    items: list[CollegeMatch],
    total: int,
    saved_ids: list[str],
    onSave: Callable[[CollegeMatch], None],
    onDismiss: Callable[[CollegeMatch], None]
) -> JsxElement {
    <section style={CARD} aria-labelledby={"bucket-" + bucket}>
        <div style={BUCKET_HEAD}>
            <h2 id={"bucket-" + bucket} style={bucket_look(bucket)}>{title}</h2>
            <span style={HINT}>{"Showing " + str(len(items)) + " of " + str(total)}</span>
        </div>
        <p style={LEDE}>{blurb}</p>
        {if len(items) == 0 {
            <p style={HINT}>No colleges in this group. Loosening a must-have may add some.</p>
        }}
        <ul style={{"listStyle": "none", "margin": "0.6rem 0 0", "padding": "0"}}>
            {for item in items {
                <ResultCard key={item.unitid} item={item} saved={item.unitid in saved_ids} onSave={onSave} onDismiss={onDismiss} />
            }}
        </ul>
    </section>
}

def:pub ResultsView -> JsxElement {
    has status: str = "loading",
        message: str = "",
        result: MatchResult | None = None,
        saved: list[dict[str, any]] = [],
        dismissed: list[str] = [];

    def saved_ids -> list[str] {
        return [kept["unitid"] as str for kept in saved];
    }

    def toggle_save(item: CollegeMatch) -> None {
        if item.unitid in saved_ids() {
            saved = [kept for kept in saved if kept["unitid"] != item.unitid];
        } else {
            saved = saved + [{
                "unitid": item.unitid,
                "name": item.name,
                "city": item.city,
                "state": item.state,
                "bucket": item.bucket,
                "fit": item.fit,
                "admit_rate": item.admit_rate,
                "net_price": item.net_price
            }];
        }
        store_saved(saved);
    }

    def dismiss(item: CollegeMatch) -> None {
        dismissed = dismissed + [item.unitid];
        store_dismissed(dismissed);
        saved = [kept for kept in saved if kept["unitid"] != item.unitid];
        store_saved(saved);
    }

    def shown(items: list[CollegeMatch]) -> list[CollegeMatch] {
        return [item for item in items if item.unitid not in dismissed];
    }

    async def load -> None {
        saved = await refresh_saved();
        dismissed = await refresh_dismissed();
        raw = None;
        try {
            raw = localStorage.getItem("jaccepted.intake");
        } except Exception {
            raw = None;
        }
        if not raw {
            status = "missing";
            return;
        }
        try {
            data = JSON.parse(raw);
            result = await match_colleges(profile_from(data));
            status = "ready";
        } except Exception as err {
            message = str(err);
            status = "error";
        }
    }

    can with entry {
        load();
    }

    <>
        <TopNav current="results" saved_count={len(saved)} />
        <div style={PAGE}>
            <header>
                <p style={EYEBROW}>Your college list</p>
                <h1 style={TITLE}>Jaccepted</h1>
                <p style={LEDE}>
                    Colleges grouped by how your scores compare with students they admit. These are estimates, not admission predictions. Fit scores out of 100 reflect your preferences.
                </p>
            </header>
            <main style={STACK}>
                {if status == "loading" {
                    <p style={HINT} role="status">Matching colleges to your profile…</p>
                }}
                {if status == "missing" {
                    <p style={BANNER} role="alert">
                        No profile found in this browser. <Link style={LINK} to="/intake">Fill out your profile</Link> first.
                    </p>
                }}
                {if status == "error" {
                    <p style={BANNER} role="alert">{"Matching failed: " + message}</p>
                }}
                {if status == "ready" and result {
                    <>
                        {len(dismissed) > 0 and <p style={HINT}>{str(len(dismissed)) + (" college" if len(dismissed) == 1 else " colleges") + " hidden as not interested."} <button type="button" style={LINK_BUTTON} onClick={lambda { dismissed = []; store_dismissed([]); }}>Show them again</button></p>}
                        {for note in result.notes {
                            <p key={note} style={HINT}>{note}</p>
                        }}
                        <p style={HINT}>
                            {str(result.reach_count + result.target_count + result.likely_count) + " of " + str(result.considered) + " four-year colleges passed your must-haves. Shortlist marks a balanced starting list: 3 reach, 4 target, 3 likely."}
                        </p>
                        <Bucket bucket="reach" title="Reach" blurb="Admit under 15% of applicants, or your scores are below their middle 50%." items={shown(result.reach)} total={result.reach_count} saved_ids={saved_ids()} onSave={toggle_save} onDismiss={dismiss} />
                        <Bucket bucket="target" title="Target" blurb="Your scores sit in their middle 50%." items={shown(result.target)} total={result.target_count} saved_ids={saved_ids()} onSave={toggle_save} onDismiss={dismiss} />
                        <Bucket bucket="likely" title="Likely" blurb="Your scores are above their middle 50% and they admit at least half of applicants." items={shown(result.likely)} total={result.likely_count} saved_ids={saved_ids()} onSave={toggle_save} onDismiss={dismiss} />
                    </>
                }}
            </main>
        </div>
    </>
}
