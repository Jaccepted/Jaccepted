"""College list results.

Reads the intake profile saved in this browser, runs matching on the server,
and shows Reach, Target, and Likely colleges with the reasons for each.
"""

import from "@jac/runtime" { Link }
import from .matching { CollegeMatch, MatchResult, Profile, match_colleges }
import from .profile_data { profile_from }
import from .list_store { refresh_dismissed, refresh_saved, store_dismissed, store_saved }
import from .components.nav { TopNav }
import from .theme {
    PICK_LIST,
    PICK_NAME,
    PICK_ROW,
    PICK_TEXT,
    PICK_WHY,
    SAVED_BUTTON,
    SAVE_BUTTON,
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
    TOOLBAR,
    TOOL_INPUT,
    TOOL_LABEL,
    bucket_look
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
    <li style={PICK_ROW}>
        <div style={PICK_TEXT}>
            <Link style={PICK_NAME} to={"/college/" + item.unitid}>{item.name}</Link>
            {item.shortlist and <span style={BADGE}>Shortlist</span>}
            <span style={{"color": "var(--muted)", "fontSize": "0.9rem"}}>{" · " + item.city + ", " + item.state}</span>
            {len(item.reasons) > 0 and <p style={PICK_WHY}>{item.reasons[0]}</p>}
        </div>
        <button type="button" style={SAVED_BUTTON if saved else SAVE_BUTTON} aria-pressed={saved} onClick={lambda { onSave(item); }}>
            {"Saved ✓" if saved else "Save"}
        </button>
        <button type="button" style={SAVE_BUTTON | {"borderColor": "var(--border)", "color": "var(--muted)"}} aria-label={"Not interested in " + item.name} onClick={lambda { onDismiss(item); }}>✕</button>
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
        <ul style={PICK_LIST | {"marginTop": "0.75rem"}}>
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
        dismissed: list[str] = [],
        profile_data: Profile | None = None,
        query: str = "",
        applied_query: str = "",
        sort_mode: str = "fit",
        busy: bool = False;

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

    async def run_match -> None {
        if profile_data is None {
            return;
        }
        busy = True;
        try {
            result = await match_colleges(profile_data, applied_query, sort_mode);
            status = "ready";
        } except Exception as err {
            message = str(err);
            status = "error";
        }
        busy = False;
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
            profile_data = profile_from(JSON.parse(raw));
        } except Exception as err {
            message = str(err);
            status = "error";
            return;
        }
        await run_match();
    }

    def on_search(e: any) -> None {
        e.preventDefault();
        applied_query = query.strip();
        run_match();
    }

    def on_sort(e: any) -> None {
        sort_mode = e.target.value;
        run_match();
    }

    def clear_search -> None {
        query = "";
        applied_query = "";
        run_match();
    }

    can with entry {
        load();
    }

    <>
        <TopNav current="results" saved_count={len(saved)} />
        <div style={PAGE}>
            <header>
                <h1 style={TITLE}>Explore</h1>
                <p style={LEDE}>
                    Every college that fits your must-haves, grouped by how your scores compare with students they admit. These are estimates, not admission predictions. Want a shortlist instead? <Link style={LINK} to="/advisor">Ask your advisor.</Link>
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
                        <form style={TOOLBAR} role="search" onSubmit={on_search}>
                            <label style={TOOL_LABEL}>
                                Search
                                <input
                                    type="search"
                                    style={TOOL_INPUT}
                                    value={query}
                                    placeholder="Name, city, or state (MI)"
                                    aria-label="Search colleges by name, city, or state"
                                    onChange={lambda (e: any) { query = e.target.value; }}
                                />
                            </label>
                            <button type="submit" style={PRIMARY} disabled={busy}>Search</button>
                            {(applied_query != "") and <button type="button" style={SECONDARY} onClick={lambda { clear_search(); }}>Clear</button>}
                            <label style={TOOL_LABEL}>
                                Sort by
                                <select style={TOOL_INPUT} value={sort_mode} aria-label="Sort colleges" onChange={on_sort}>
                                    <option value="fit">Best fit</option>
                                    <option value="admit">Lowest admit rate</option>
                                    <option value="price">Lowest net price</option>
                                    <option value="distance">Closest to home</option>
                                    <option value="name">Name (A to Z)</option>
                                </select>
                            </label>
                        </form>
                        {applied_query != "" and <p style={HINT}>{"Showing colleges matching \"" + applied_query + "\"."}</p>}
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
