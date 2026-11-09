"""The advisor conversation, shared by the Advisor page and the chat bubble.

Each answer shows what the agent did, its picks with one reason each, and
follow-ups the student can tap. The conversation stays in this browser, so the
page and the bubble show the same chat.
"""

import from "@jac/runtime" { Link }
import from .advisor { AdvisorChoice, AdvisorResult, ask_advisor }
import from .matching { CollegeMatch, Profile, starting_list }
import from .profile_data { profile_from }
import from .list_store { refresh_saved, store_saved }
import from .components.spinner { Spinner }
import from .components.logo { LogoMark }
import from .theme {
    AGENT_BODY,
    AGENT_ROW,
    BANNER,
    COMPOSER,
    COMPOSER_ROW,
    CONTROL,
    FOLLOW_UP,
    HINT,
    LEDE,
    LINK,
    ME_BUBBLE,
    PICK_LIST,
    PICK_NAME,
    PICK_ROW,
    PICK_TEXT,
    PICK_WHY,
    PRIMARY,
    SAVED_BUTTON,
    SAVE_BUTTON,
    STACK,
    STEP_BOX,
    STEP_LIST,
    TITLE,
    bucket_chip
}

glob STARTERS: list[str] = [
    "Build me a balanced starting list.",
    "Find affordable likely schools under $20,000 a year.",
    "Show me strong options within 300 miles of home.",
    "Which colleges fit my major best?"
];

glob CONVERSATION_KEY: str = "jaccepted.advisor";

# Which request the quick starting list belongs to. A list that arrives after
# the advisor has answered (or after a newer request began) is thrown away.
# Kept outside the component so a late response sees the current value.
glob PREVIEW_RUN: dict[str, int] = {"current": 0};

glob WEIGHT_NAMES: dict[str, str] = {
    "price": "cost", "location": "location", "distance": "distance", "setting": "campus setting",
    "size": "size", "type": "public/private", "outcomes": "graduation and earnings", "major": "your major",
    "religion": "religious affiliation", "hbcu": "HBCU", "womens": "women's colleges"
};

"""Custom priorities in words, for example "cost ×2 · location ×0"."""
def weights_text(weights: dict[str, float]) -> str {
    parts: list[str] = [];
    for key in Object.keys(weights) {
        parts.append((WEIGHT_NAMES[key] or key) + " ×" + str(weights[key]));
    }
    return " · ".join(parts);
}

glob THINKING: list[str] = [
    "Reading your request…",
    "Searching colleges that fit your must-haves…",
    "Comparing reach, target and likely options…",
    "Looking into the strongest candidates…",
    "Checking your list's balance…",
    "Writing up the picks…"
];

def bucket_name(bucket: str) -> str {
    if bucket == "reach" {
        return "Reach";
    }
    if bucket == "target" {
        return "Target";
    }
    return "Likely";
}

def plural(count: int, word: str) -> str {
    return str(count) + " " + word;
}

def PickRow(item: AdvisorChoice, saved: bool, onSave: Callable[[AdvisorChoice], None]) -> JsxElement {
    <li style={PICK_ROW}>
        <div style={PICK_TEXT}>
            <span style={bucket_chip(item.bucket)}>{bucket_name(item.bucket)}</span>
            <Link style={PICK_NAME} to={"/college/" + item.unitid}>{item.name}</Link>
            <span style={{"color": "var(--muted)", "fontSize": "0.9rem"}}>{" · " + item.city + ", " + item.state}</span>
            <p style={PICK_WHY}>{item.why}</p>
        </div>
        <button type="button" style={SAVED_BUTTON if saved else SAVE_BUTTON} aria-pressed={saved} onClick={lambda { onSave(item); }}>
            {"Saved ✓" if saved else "Save"}
        </button>
    </li>
}

"""A rule-based match shown while the advisor works. It opens in a new tab so the request keeps running."""
def PreviewRow(item: CollegeMatch) -> JsxElement {
    <li style={PICK_ROW}>
        <div style={PICK_TEXT}>
            <span style={bucket_chip(item.bucket)}>{bucket_name(item.bucket)}</span>
            <a style={PICK_NAME} href={"/college/" + item.unitid} target="_blank" rel="noreferrer">{item.name}</a>
            <span style={{"color": "var(--muted)", "fontSize": "0.9rem"}}>{" · " + item.city + ", " + item.state}</span>
            <p style={PICK_WHY}>{item.reasons[0] if len(item.reasons) > 0 else ""}</p>
        </div>
    </li>
}

def AgentTurn(
    result: AdvisorResult,
    fallback: list[CollegeMatch],
    compact: bool,
    saved_ids: list[str],
    onSave: Callable[[AdvisorChoice], None],
    onFollow: Callable[[str], None]
) -> JsxElement {
    <div style={AGENT_ROW}>
        <LogoMark size={28 if compact else 32} />
        <div style={AGENT_BODY}>
            {if not result.ok {
                <>
                    <p style={BANNER} role="alert">{result.message}</p>
                    {len(fallback) > 0 and <>
                        <p style={{"margin": "0", "lineHeight": "1.55"}}>
                            <strong>In the meantime, here is a starting list from your profile.</strong> It is matched by rules, with no AI, so it has no advisor reasoning.
                        </p>
                        <ul style={PICK_LIST} aria-label="Starting list">
                            {for item in fallback {
                                <PreviewRow key={item.unitid} item={item} />
                            }}
                        </ul>
                    </>}
                </>
            } else {
                <>
                    {len(result.steps) > 0 and <details style={STEP_BOX} open={not compact}>
                        <summary style={{"cursor": "pointer", "fontWeight": "600", "color": "var(--accent-text)"}}>
                            {"What I did (" + plural(len(result.steps), "steps") + ")"}
                        </summary>
                        <ol style={STEP_LIST}>
                            {for step in result.steps {
                                <li key={step}>{"✓ " + step}</li>
                            }}
                        </ol>
                    </details>}
                    <p style={{"margin": "0", "lineHeight": "1.55"}}>{result.message}</p>
                    {len(result.picks) > 0 and <>
                        <ul style={PICK_LIST} aria-label="Recommended colleges">
                            {for item in result.picks {
                                <PickRow key={item.unitid} item={item} saved={item.unitid in saved_ids} onSave={onSave} />
                            }}
                        </ul>
                        <p style={HINT}>
                            {plural(result.reach, "reach") + " · " + plural(result.target, "target") + " · " + plural(result.likely, "likely") + ". Estimates from public data, not admission predictions."}
                        </p>
                    </>}
                    {len(result.follow_ups) > 0 and <div style={{"display": "flex", "flexWrap": "wrap", "gap": "0.5rem"}}>
                        {for text in result.follow_ups {
                            <button key={text} type="button" style={FOLLOW_UP} onClick={lambda { onFollow(text); }}>{text}</button>
                        }}
                    </div>}
                </>
            }}
        </div>
    </div>
}

"""The conversation. compact is the chat-bubble layout; autostart sends the first request when arriving from the profile."""
def:pub AdvisorChat(compact: bool = False, autostart: bool = False, onSavedCount: any = None) -> JsxElement {
    has draft: str = "",
        thinking: bool = False,
        tick: int = 0,
        timer: any = None,
        missing: bool = False,
        questions: list[str] = [],
        answers: list[AdvisorResult] = [],
        weights: dict[str, float] = {},
        weights_saved: bool = False,
        live_steps: list[str] = [],
        preview: list[CollegeMatch] = [],
        fallbacks: dict[str, list[CollegeMatch]] = {},
        saved: list[dict[str, any]] = [];

    def remember -> None {
        try {
            localStorage.setItem(CONVERSATION_KEY, JSON.stringify({"questions": questions, "answers": answers, "weights": weights, "fallbacks": fallbacks}));
        } except Exception {
            return;
        }
    }

    def restore -> None {
        try {
            raw = localStorage.getItem(CONVERSATION_KEY);
            if raw {
                data: any = JSON.parse(raw);
                saved_questions = data["questions"] as list[str];
                saved_answers = data["answers"] as list[AdvisorResult];
                if saved_questions and saved_answers and len(saved_questions) == len(saved_answers) {
                    questions = saved_questions;
                    answers = saved_answers;
                }
                if data["weights"] {
                    weights = data["weights"] as dict[str, float];
                }
                if data["fallbacks"] {
                    fallbacks = data["fallbacks"] as dict[str, list[CollegeMatch]];
                }
            }
        } except Exception {
            return;
        }
    }

    def current_list -> list[str] {
        for index in range(len(answers) - 1, -1, -1) {
            if answers[index].ok and len(answers[index].picks) > 0 {
                return [item.unitid for item in answers[index].picks];
            }
        }
        return [];
    }

    def scroll_down -> None {
        setTimeout(lambda {
            anchor: any = document.getElementById("advisor-end-" + ("bubble" if compact else "page"));
            if anchor {
                anchor.scrollIntoView({"behavior": "smooth", "block": "end"});
            }
        }, 60);
    }

    def start_ticking -> None {
        tick = 0;
        timer = setInterval(lambda { tick = tick + 1; }, 2600);
    }

    def stop_ticking -> None {
        if timer {
            clearInterval(timer);
        }
        timer = None;
    }

    """Ask through the streaming endpoint, showing each real step as it arrives.
    Returns None if streaming isn't available, so the caller can fall back."""
    async def ask_live(question: str, profile: Profile) -> any {
        resp = await fetch("/function/ask_advisor_live", {
            "method": "POST",
            "headers": {"Content-Type": "application/json", "Authorization": "Bearer " + (localStorage.getItem("jac_token") or "")},
            "body": JSON.stringify({"question": question, "profile": profile, "current_list": current_list()})
        });
        if not resp.ok or not resp.body {
            return None;
        }
        reader = resp.body.getReader();
        decoder = new(TextDecoder);
        nl = chr(10);
        buf = "";
        shown: list[str] = [];
        final: any = None;
        reading = True;
        while reading {
            part = await reader.read();
            if part.done {
                reading = False;
                continue;
            }
            buf = buf + decoder.decode(part.value, {"stream": True});
            frames = buf.split(nl + nl);
            buf = frames.pop();
            for frame in frames {
                for line in frame.split(nl) {
                    if line.startswith("data: ") and not frame.startswith("event:") {
                        payload: any = JSON.parse(line[6:]);
                        if payload and payload["step"] {
                            shown = shown + [payload["step"] as str];
                            live_steps = shown;
                            scroll_down();
                        } elif payload and payload["result"] {
                            final = payload["result"];
                        }
                    }
                }
            }
        }
        return final;
    }

    """Fetch the quick rule-based list in parallel with the advisor. Never blocks or fails the request.
    Returns the list so a failed advisor request can still show it."""
    async def load_preview(profile: Profile, mine: int) -> list[CollegeMatch] {
        try {
            found = await starting_list(profile, 4 if compact else 10);
            if PREVIEW_RUN["current"] == mine and len(found) > 0 {
                preview = found;
            }
            return found;
        } except Exception {
            return [];
        }
    }

    async def send(text: str) -> None {
        question = text.strip();
        if not question or thinking {
            return;
        }
        raw = None;
        try {
            raw = localStorage.getItem("jaccepted.intake");
        } except Exception {
            raw = None;
        }
        if not raw {
            missing = True;
            return;
        }
        draft = "";
        thinking = True;
        live_steps = [];
        preview = [];
        PREVIEW_RUN["current"] = PREVIEW_RUN["current"] + 1;
        mine = PREVIEW_RUN["current"];
        first_list = len(current_list()) == 0;
        preview_task: any = None;
        start_ticking();
        questions = questions + [question];
        scroll_down();
        answer = AdvisorResult(ok=False, message="The advisor is unavailable right now. Explore still works.");
        try {
            profile = profile_from(JSON.parse(raw));
            if len(Object.keys(weights)) > 0 {
                profile.weights = weights;
            }
            # Only for a first list. Later requests refine a list the student already has.
            if first_list {
                preview_task = load_preview(profile, mine);
            }
            streamed: any = None;
            try {
                streamed = await ask_live(question, profile);
            } except Exception {
                streamed = None;
            }
            if streamed {
                answer = streamed;
            } else {
                answer = await ask_advisor(question, profile, current_list());
            }
        } except Exception {
            answer = AdvisorResult(ok=False, message="The advisor is unavailable right now. Explore still works.");
        }
        if not answer.ok and preview_task {
            kept: list[CollegeMatch] = [];
            try {
                # Wait briefly for the quick list, but never hold up the error message for it.
                gave_up = new(Promise, lambda (resolve: any) { setTimeout(lambda { resolve([]); }, 4000); });
                raced: any = await Promise.race([preview_task, gave_up]);
                kept = raced as list[CollegeMatch];
            } except Exception {
                kept = [];
            }
            if len(kept) > 0 {
                fallbacks = fallbacks | {str(len(answers)): kept};
            }
        }
        answers = answers + [answer];
        if answer.ok and answer.weights {
            if JSON.stringify(answer.weights) != JSON.stringify(weights) {
                weights_saved = False;
            }
            weights = answer.weights;
        }
        PREVIEW_RUN["current"] = PREVIEW_RUN["current"] + 1;
        preview = [];
        thinking = False;
        stop_ticking();
        remember();
        scroll_down();
    }

    async def load -> None {
        restore();
        if compact {
            scroll_down();
        }
        saved = await refresh_saved();
        starting = False;
        if autostart {
            try {
                starting = "start=1" in window.location.search;
                if starting {
                    window.history.replaceState({}, "", "/advisor");
                }
            } except Exception {
                starting = False;
            }
        }
        if starting and len(questions) == 0 {
            await send(STARTERS[0]);
        }
    }

    can with entry {
        load();
    }

    can with exit {
        stop_ticking();
    }

    def saved_ids -> list[str] {
        return [kept["unitid"] as str for kept in saved];
    }

    def toggle_save(item: AdvisorChoice) -> None {
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
        if onSavedCount {
            onSavedCount(len(saved));
        }
    }

    def start_over -> None {
        questions = [];
        answers = [];
        fallbacks = {};
        remember();
    }

    def write_profile_weights(value: dict[str, float]) -> None {
        try {
            raw = localStorage.getItem("jaccepted.intake");
            if raw {
                data: any = JSON.parse(raw);
                data["weights"] = value;
                localStorage.setItem("jaccepted.intake", JSON.stringify(data));
            }
        } except Exception {
            return;
        }
    }

    def save_weights -> None {
        write_profile_weights(weights);
        weights_saved = True;
    }

    def reset_weights -> None {
        weights = {};
        weights_saved = False;
        write_profile_weights({});
        remember();
    }

    def on_submit(e: any) -> None {
        e.preventDefault();
        send(draft);
    }

    def on_key(e: any) -> None {
        if e.key == "Enter" and not e.shiftKey {
            e.preventDefault();
            send(draft);
        }
    }

    starters = STARTERS[:2] if compact else STARTERS;
    status = THINKING[min(tick, len(THINKING) - 1)];

    <div style={{"display": "flex", "flexDirection": "column", "minHeight": "100%"}}>
        <div style={STACK | {"flex": "1", "marginTop": "0"}}>
            {if len(questions) == 0 {
                <section aria-labelledby="advisor-title" style={{"padding": "0.25rem 0 0.25rem" if compact else "1.5rem 0 0.5rem"}}>
                    {not compact and <LogoMark size={44} />}
                    <h1 id="advisor-title" style={TITLE | {"marginTop": "0.9rem", "fontSize": "1.15rem" if compact else "2rem"}}>What kind of college list do you want?</h1>
                    <p style={LEDE | {"fontSize": "0.95rem"} if compact else LEDE}>
                        I search the colleges that fit your profile, check that your list is balanced, and explain every pick. I only use real college data, and I never predict whether you'll get in.
                    </p>
                    <div style={{"display": "flex", "flexWrap": "wrap", "gap": "0.5rem", "marginTop": "1rem"}}>
                        {for text in starters {
                            <button key={text} type="button" style={FOLLOW_UP} onClick={lambda { send(text); }}>{text}</button>
                        }}
                    </div>
                </section>
            } else {
                <div style={{"display": "flex", "justifyContent": "space-between", "alignItems": "center", "gap": "0.5rem"}}>
                    {compact and <span></span>}
                    {not compact and <h1 style={{"margin": "0", "fontSize": "1.4rem"}}>Your advisor</h1>}
                    <button type="button" style={FOLLOW_UP} onClick={start_over} disabled={thinking}>Start over</button>
                </div>
            }}
            {if len(Object.keys(weights)) > 0 {
                <div style={{"display": "flex", "flexWrap": "wrap", "alignItems": "center", "gap": "0.5rem", "padding": "0.6rem 0.8rem", "border": "1px solid var(--border)", "borderRadius": "12px", "background": "var(--tint)", "animation": "jac-rise 0.25s ease-out"}} role="status">
                    <span style={{"flex": "1 1 12rem"}}>
                        <strong style={{"color": "var(--accent-text)"}}>Custom priorities: </strong>{weights_text(weights)}
                    </span>
                    <button type="button" style={FOLLOW_UP} onClick={save_weights} disabled={weights_saved}>{"Saved to profile ✓" if weights_saved else "Save to profile"}</button>
                    <button type="button" style={FOLLOW_UP} onClick={reset_weights}>Reset</button>
                </div>
            }}
            {if missing {
                <p style={BANNER} role="alert">
                    I need your profile first. <Link style={LINK} to="/intake">Fill out your profile</Link>, then come back.
                </p>
            }}
            <div style={{"display": "flex", "flexDirection": "column", "gap": "1.25rem"}} aria-live="polite">
                {for (index, question) in enumerate(questions) {
                    <div key={str(index)} style={{"display": "flex", "flexDirection": "column", "gap": "1rem", "animation": "jac-rise 0.3s ease-out"}}>
                        <div style={ME_BUBBLE}>{question}</div>
                        {if index < len(answers) {
                            <AgentTurn
                                result={answers[index]}
                                fallback={fallbacks[str(index)] or []}
                                compact={compact}
                                saved_ids={saved_ids()}
                                onSave={toggle_save}
                                onFollow={lambda (text: str) { send(text); }}
                            />
                        }}
                    </div>
                }}
                {if thinking {
                    <div style={AGENT_ROW} role="status" aria-label="The advisor is working">
                        <span style={{"display": "inline-flex", "borderRadius": "10px", "animation": "jac-pulse 1.6s ease-in-out infinite"}}>
                            <LogoMark size={28 if compact else 32} />
                        </span>
                        <div style={STEP_BOX | {"flex": "1", "minWidth": "0", "boxShadow": "var(--glow)"}}>
                            {len(live_steps) > 0 and <ol style={STEP_LIST | {"margin": "0 0 0.5rem"}}>
                                {for step in live_steps {
                                    <li key={step} style={{"animation": "jac-rise 0.3s ease-out"}}>{"✓ " + step}</li>
                                }}
                            </ol>}
                            <div style={{"display": "flex", "alignItems": "center", "gap": "0.7rem"}}>
                                <span style={{"color": "var(--accent-text)", "display": "inline-flex"}}>
                                    <Spinner size={22} label="Thinking" />
                                </span>
                                <div>
                                    <strong style={{"color": "var(--accent-text)"}}>{"Thinking about your picks…" if len(live_steps) > 0 else status}</strong>
                                    {not compact and len(live_steps) == 0 and <p style={{"margin": "0.2rem 0 0", "color": "var(--muted)", "fontSize": "0.9rem"}}>This usually takes about 10 seconds.</p>}
                                </div>
                            </div>
                            {len(preview) > 0 and <div style={{"marginTop": "0.9rem", "paddingTop": "0.8rem", "borderTop": "1px solid var(--border)", "animation": "jac-rise 0.3s ease-out"}}>
                                <strong>A quick start while I work</strong>
                                <p style={HINT}>Matched from your profile by the rules, no AI yet. I'm still checking these and will refine the list.</p>
                                <ul style={PICK_LIST} aria-label="Quick starting list">
                                    {for item in preview {
                                        <PreviewRow key={item.unitid} item={item} />
                                    }}
                                </ul>
                            </div>}
                        </div>
                    </div>
                }}
                <div id={"advisor-end-" + ("bubble" if compact else "page")}></div>
            </div>
        </div>
        <form style={COMPOSER | ({"bottom": "-0.9rem", "paddingBottom": "0.9rem"} if compact else {})} onSubmit={on_submit}>
            <label htmlFor={"advisor-input-" + ("bubble" if compact else "page")} style={{"position": "absolute", "left": "-9999px"}}>Message the advisor</label>
            <div style={COMPOSER_ROW}>
                <textarea
                    id={"advisor-input-" + ("bubble" if compact else "page")}
                    rows={2}
                    maxLength={600}
                    value={draft}
                    placeholder={"Ask for a list, or say what to change…" if len(questions) > 0 else "Describe the list you want…"}
                    style={CONTROL | {"resize": "none"}}
                    onChange={lambda (e: any) { draft = e.target.value; }}
                    onKeyDown={on_key}
                />
                <button type="submit" style={PRIMARY | {"display": "inline-flex", "alignItems": "center", "gap": "0.45rem"}} disabled={thinking or not draft.strip()}>
                    {thinking and <Spinner size={16} label="Thinking" />}
                    {"Thinking" if thinking else "Send"}
                </button>
            </div>
        </form>
    </div>
}
