"""Results page: shows Reach / Target / Likely colleges for the saved profile."""

import from "@jac/runtime" { Link }
import from ..format { fmt_rate, fmt_price, fmt_sat, fmt_act }
import from ..matcher { match_colleges, MatchResult, MatchResponse }
import from ..theme {
    Shell,
    RESULTS_PAGE,
    BUCKETS_GRID,
    BUCKET_COL,
    BUCKET_HEAD,
    BUCKET_LABEL_REACH,
    BUCKET_LABEL_TARGET,
    BUCKET_LABEL_LIKELY,
    BUCKET_COUNT,
    COLLEGE_CARD,
    COLLEGE_NAME,
    COLLEGE_LOCATION,
    CARD_STATS,
    STAT_ITEM,
    BUCKET_REASON_TEXT,
    FIT_BADGE,
    BALANCE_BAR,
    BALANCE_ITEM,
    EMPTY_BUCKET,
    LOADING_BOX,
    EYEBROW,
    TITLE,
    LEDE,
    BANNER,
    SECONDARY,
    COLLEGE_LINK,
    CARD_ACTIONS,
    SMALL_BTN,
    SMALL_BTN_ON,
    TOOLBAR,
    TOOL_CONTROL,
    REASONS_LIST,
    REASONS_SUMMARY,
    SECTION_HEAD,
    DISCLAIMER
}

def CollegeCard(
    college: MatchResult,
    saved: bool,
    onSave: Callable[[str], None],
    onDismiss: Callable[[str], None]
) -> JsxElement {
    price = college.net_price_for_bracket;
    if price is None {
        price = college.net_price;
    }
    sat_range = fmt_sat(college.sat_composite_p25, college.sat_composite_p75);
    act_range = fmt_act(college.act_p25, college.act_p75);
    save_label = "Saved ✓" if saved else "Save";
    save_style = SMALL_BTN_ON if saved else SMALL_BTN;
    <div style={COLLEGE_CARD}>
        <p style={COLLEGE_NAME}><Link to={"/college/" + college.unitid} style={COLLEGE_LINK}>{college.name}</Link></p>
        <p style={COLLEGE_LOCATION}>{college.city}, {college.state}</p>
        <div style={CARD_STATS}>
            <span style={STAT_ITEM}>Admit: {fmt_rate(college.admit_rate)}</span>
            {sat_range and <span style={STAT_ITEM}>SAT: {sat_range}</span>}
            {(not sat_range) and act_range and <span style={STAT_ITEM}>ACT: {act_range}</span>}
            <span style={STAT_ITEM}>Net price: {fmt_price(price)}</span>
        </div>
        <p style={BUCKET_REASON_TEXT}>{college.bucket_reason}</p>
        <span style={FIT_BADGE}>Fit {college.fit_score}/100</span>
        {len(college.fit_reasons) > 0 and
            <details>
                <summary style={REASONS_SUMMARY}>Why this fits</summary>
                <ul style={REASONS_LIST}>
                    {for r in college.fit_reasons {
                        <li key={r}>{r}</li>
                    }}
                </ul>
            </details>
        }
        <div style={CARD_ACTIONS}>
            <button type="button" style={save_style} onClick={lambda { onSave(college.unitid); }}>{save_label}</button>
            <button type="button" style={SMALL_BTN} onClick={lambda { onDismiss(college.unitid); }}>Not interested</button>
        </div>
    </div>
}

def BucketSection(
    bucket: str,
    colleges: list[MatchResult],
    saved_ids: list[str],
    onSave: Callable[[str], None],
    onDismiss: Callable[[str], None]
) -> JsxElement {
    label_style = BUCKET_LABEL_TARGET;
    if bucket == "reach" {
        label_style = BUCKET_LABEL_REACH;
    } elif bucket == "likely" {
        label_style = BUCKET_LABEL_LIKELY;
    }
    label = bucket[0].upper() + bucket[1:];
    count_text = str(len(colleges)) + (" school" if len(colleges) == 1 else " schools");
    <div style={BUCKET_COL}>
        <div style={BUCKET_HEAD}>
            <p style={label_style}>{label}</p>
            <p style={BUCKET_COUNT}>{count_text}</p>
        </div>
        {if len(colleges) == 0 {
            <div style={EMPTY_BUCKET}>
                No schools to show here given your preferences and filters.
            </div>
        } else {
            <div style={{"display": "flex", "flexDirection": "column", "gap": "0.75rem"}}>
                {for c in colleges {
                    <CollegeCard key={c.unitid} college={c} saved={c.unitid in saved_ids} onSave={onSave} onDismiss={onDismiss} />
                }}
            </div>
        }}
    </div>
}

def sort_key(c: MatchResult, mode: str) -> float {
    if mode == "admit" {
        return c.admit_rate if c.admit_rate is not None else 2.0;
    }
    if mode == "price" {
        p = c.net_price_for_bracket;
        if p is None {
            p = c.net_price;
        }
        return float(p) if p is not None else 1e9;
    }
    return -float(c.fit_score);
}

def visible(
    colleges: list[MatchResult],
    dismissed_ids: list[str],
    query: str,
    sort_mode: str
) -> list[MatchResult] {
    q = query.strip().lower();
    out: list[MatchResult] = [];
    for c in colleges {
        if c.unitid in dismissed_ids {
            continue;
        }
        if q and (q not in c.name.lower()) and (q != c.state.lower()) {
            continue;
        }
        out.append(c);
    }
    # Keys are ascending: fit is negated so the best fit comes first.
    out.sort(key=lambda (c: MatchResult) { sort_key(c, sort_mode); });
    return out;
}

def:pub Results -> JsxPage {
    has response: MatchResponse | None = None,
        loading: bool = True,
        error: str = "",
        saved_ids: list[str] = [],
        dismissed_ids: list[str] = [],
        query: str = "",
        sort_mode: str = "fit",
        show_saved: bool = False;

    def persist_lists -> None {
        try {
            localStorage.setItem("jaccepted.list", JSON.stringify({"saved": saved_ids, "dismissed": dismissed_ids}));
        } except Exception {
            return;
        }
    }

    def toggle_save(uid: str) -> None {
        if uid in saved_ids {
            saved_ids = [i for i in saved_ids if i != uid];
        } else {
            saved_ids = saved_ids + [uid];
        }
        persist_lists();
    }

    def dismiss(uid: str) -> None {
        dismissed_ids = dismissed_ids + [uid];
        saved_ids = [i for i in saved_ids if i != uid];
        persist_lists();
    }

    def restore_dismissed -> None {
        dismissed_ids = [];
        persist_lists();
    }

    async can with entry {
        try {
            stored = localStorage.getItem("jaccepted.list");
            if stored {
                lists: any = JSON.parse(stored);
                saved_ids = lists.saved or [];
                dismissed_ids = lists.dismissed or [];
            }
        } except Exception {
            saved_ids = [];
        }
        try {
            raw = localStorage.getItem("jaccepted.intake");
            if not raw {
                error = "No profile found. Please complete the intake form first.";
                loading = False;
                return;
            }
            profile = JSON.parse(raw);
            data = await match_colleges(profile);
            response = data;
        } except Exception as e {
            error = str(e);
        }
        loading = False;
    }

    reach: list[MatchResult] = [];
    target: list[MatchResult] = [];
    likely: list[MatchResult] = [];
    if response is not None {
        reach = visible(response.reach, dismissed_ids, query, sort_mode);
        target = visible(response.target, dismissed_ids, query, sort_mode);
        likely = visible(response.likely, dismissed_ids, query, sort_mode);
    }
    if show_saved {
        reach = [c for c in reach if c.unitid in saved_ids];
        target = [c for c in target if c.unitid in saved_ids];
        likely = [c for c in likely if c.unitid in saved_ids];
    }

    # Balance check runs on the saved list (My List), not on all results.
    s_reach = 0;
    s_target = 0;
    s_likely = 0;
    if response is not None {
        s_reach = len([c for c in response.reach if c.unitid in saved_ids]);
        s_target = len([c for c in response.target if c.unitid in saved_ids]);
        s_likely = len([c for c in response.likely if c.unitid in saved_ids]);
    }
    s_total = s_reach + s_target + s_likely;
    balance_msg = "";
    if s_total > 0 {
        if s_likely == 0 {
            balance_msg = "Your list has no Likely schools. Save at least one so you have a safe option.";
        } elif s_reach > (s_target + s_likely) * 2 {
            balance_msg = "Your list is reach-heavy. Consider saving more Target or Likely schools.";
        }
    }

    toggle_label = "Showing My List" if show_saved else "Show My List only";
    toggle_style = SMALL_BTN_ON if show_saved else SMALL_BTN;

    <Shell>
        <div style={RESULTS_PAGE}>
            <header>
                <p style={EYEBROW}>Your matches</p>
                <h1 style={TITLE}>Jaccepted</h1>
                <p style={LEDE}>
                    Colleges are ranked within each bucket by how well they match your preferences.
                </p>
                <p style={DISCLAIMER}>
                    Reach, Target and Likely are estimates based on public data. They are not admission
                    decisions and nothing here guarantees admission.
                </p>
                <div style={{"marginTop": "0.75rem"}}>
                    <Link to="/intake" style={SECONDARY}>Edit profile</Link>
                </div>
            </header>

            {if loading {
                <div style={LOADING_BOX}>
                    <p>Matching your profile against colleges…</p>
                </div>
            } elif error {
                <div style={BANNER} role="alert">
                    {error}
                    {" "}
                    <Link to="/intake">Go to intake →</Link>
                </div>
            } else {
                <div>
                    <div style={BALANCE_BAR}>
                        <span>
                            {"My List: " + str(s_total) + " saved  ·  " + str(s_reach) + " Reach  ·  " + str(s_target) + " Target  ·  " + str(s_likely) + " Likely"}
                        </span>
                        {balance_msg and
                            <span style={{"color": "#8e2432", "fontSize": "0.875rem"}}>
                                {balance_msg}
                            </span>
                        }
                    </div>
                    <div style={TOOLBAR}>
                        <input
                            type="search"
                            placeholder="Filter by name or state (e.g. MI)"
                            value={query}
                            aria-label="Filter colleges"
                            style={TOOL_CONTROL}
                            onChange={lambda (e: any) { query = e.target.value; }}
                        />
                        <select
                            value={sort_mode}
                            aria-label="Sort colleges"
                            style={TOOL_CONTROL}
                            onChange={lambda (e: any) { sort_mode = e.target.value; }}
                        >
                            <option value="fit">Sort: best fit</option>
                            <option value="admit">Sort: lowest admit rate</option>
                            <option value="price">Sort: lowest net price</option>
                        </select>
                        <button type="button" style={toggle_style} onClick={lambda { show_saved = not show_saved; }}>{toggle_label}</button>
                        {len(dismissed_ids) > 0 and
                            <button type="button" style={SMALL_BTN} onClick={lambda { restore_dismissed(); }}>
                                {"Restore " + str(len(dismissed_ids)) + " hidden"}
                            </button>
                        }
                    </div>
                    {response is not None and
                        <div style={BUCKETS_GRID}>
                            <BucketSection bucket="reach" colleges={reach} saved_ids={saved_ids} onSave={toggle_save} onDismiss={dismiss} />
                            <BucketSection bucket="target" colleges={target} saved_ids={saved_ids} onSave={toggle_save} onDismiss={dismiss} />
                            <BucketSection bucket="likely" colleges={likely} saved_ids={saved_ids} onSave={toggle_save} onDismiss={dismiss} />
                        </div>
                    }
                </div>
            }}
        </div>
    </Shell>
}
