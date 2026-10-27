"""AI advisor: a conversation where the agent builds and refines the student's list.

Each answer shows what the agent did, its picks with one reason each, and
follow-ups the student can tap. The conversation stays in this browser.
"""

import from "@jac/runtime" { Link }
import from .advisor { AdvisorChoice, AdvisorResult, ask_advisor }
import from .results { profile_from }
import from .list_store { refresh_saved, store_saved }
import from .components.nav { TopNav }
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
    WIDE_PAGE,
    bucket_chip
}

glob STARTERS: list[str] = [
    "Build me a balanced starting list.",
    "Find affordable likely schools under $20,000 a year.",
    "Show me strong options within 300 miles of home.",
    "Which colleges fit my major best?"
];

glob CONVERSATION_KEY: str = "jaccepted.advisor";

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
            <span style={{"color": "#5a6470", "fontSize": "0.9rem"}}>{" · " + item.city + ", " + item.state}</span>
            <p style={PICK_WHY}>{item.why}</p>
        </div>
        <button type="button" style={SAVED_BUTTON if saved else SAVE_BUTTON} aria-pressed={saved} onClick={lambda { onSave(item); }}>
            {"Saved ✓" if saved else "Save"}
        </button>
    </li>
}

def AgentTurn(
    result: AdvisorResult,
    saved_ids: list[str],
    onSave: Callable[[AdvisorChoice], None],
    onFollow: Callable[[str], None]
) -> JsxElement {
    <div style={AGENT_ROW}>
        <LogoMark size={32} />
        <div style={AGENT_BODY}>
            {if not result.ok {
                <p style={BANNER} role="alert">{result.message}</p>
            } else {
                <>
                    {len(result.steps) > 0 and <details style={STEP_BOX} open={True}>
                        <summary style={{"cursor": "pointer", "fontWeight": "600", "color": "#0f5c4c"}}>
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

def:pub AdvisorView -> JsxElement {
    has draft: str = "",
        thinking: bool = False,
        missing: bool = False,
        questions: list[str] = [],
        answers: list[AdvisorResult] = [],
        saved: list[dict[str, any]] = [];

    def remember -> None {
        try {
            localStorage.setItem(CONVERSATION_KEY, JSON.stringify({"questions": questions, "answers": answers}));
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
        questions = questions + [question];
        answer = AdvisorResult(ok=False, message="The advisor is unavailable right now. Explore still works.");
        try {
            answer = await ask_advisor(question, profile_from(JSON.parse(raw)), current_list());
        } except Exception {
            answer = AdvisorResult(ok=False, message="The advisor is unavailable right now. Explore still works.");
        }
        answers = answers + [answer];
        thinking = False;
        remember();
    }

    async def load -> None {
        restore();
        saved = await refresh_saved();
        starting = False;
        try {
            starting = "start=1" in window.location.search;
            if starting {
                window.history.replaceState({}, "", "/advisor");
            }
        } except Exception {
            starting = False;
        }
        if starting and len(questions) == 0 {
            await send(STARTERS[0]);
        }
    }

    can with entry {
        load();
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
    }

    def start_over -> None {
        questions = [];
        answers = [];
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

    <>
        <TopNav current="advisor" saved_count={len(saved)} />
        <div style={WIDE_PAGE}>
            <main style={STACK}>
                {if len(questions) == 0 {
                    <section aria-labelledby="advisor-title" style={{"padding": "1.5rem 0 0.5rem"}}>
                        <LogoMark size={44} />
                        <h1 id="advisor-title" style={TITLE | {"marginTop": "0.9rem"}}>What kind of college list do you want?</h1>
                        <p style={LEDE}>
                            I search the colleges that fit your profile, check that your list is balanced, and explain every pick. I only use real college data, and I never predict whether you'll get in.
                        </p>
                        <div style={{"display": "flex", "flexWrap": "wrap", "gap": "0.5rem", "marginTop": "1.1rem"}}>
                            {for text in STARTERS {
                                <button key={text} type="button" style={FOLLOW_UP} onClick={lambda { send(text); }}>{text}</button>
                            }}
                        </div>
                    </section>
                } else {
                    <div style={{"display": "flex", "justifyContent": "space-between", "alignItems": "center"}}>
                        <h1 style={{"margin": "0", "fontSize": "1.4rem"}}>Your advisor</h1>
                        <button type="button" style={FOLLOW_UP} onClick={start_over}>Start over</button>
                    </div>
                }}
                {if missing {
                    <p style={BANNER} role="alert">
                        I need your profile first. <Link style={LINK} to="/intake">Fill out your profile</Link>, then come back.
                    </p>
                }}
                <div style={{"display": "flex", "flexDirection": "column", "gap": "1.25rem"}} aria-live="polite">
                    {for (index, question) in enumerate(questions) {
                        <div key={str(index)} style={{"display": "flex", "flexDirection": "column", "gap": "1rem"}}>
                            <div style={ME_BUBBLE}>{question}</div>
                            {if index < len(answers) {
                                <AgentTurn
                                    result={answers[index]}
                                    saved_ids={saved_ids()}
                                    onSave={toggle_save}
                                    onFollow={lambda (text: str) { send(text); }}
                                />
                            }}
                        </div>
                    }}
                    {if thinking {
                        <div style={AGENT_ROW} role="status">
                            <LogoMark size={32} />
                            <div style={STEP_BOX}>
                                <strong style={{"color": "#0f5c4c"}}>Working on it…</strong>
                                <p style={{"margin": "0.3rem 0 0", "color": "#5a6470", "fontSize": "0.92rem"}}>
                                    Searching your matches, comparing options and checking your list's balance. This can take up to a minute.
                                </p>
                            </div>
                        </div>
                    }}
                </div>
            </main>
            <form style={COMPOSER} onSubmit={on_submit}>
                <label htmlFor="advisor-input" style={{"position": "absolute", "left": "-9999px"}}>Message the advisor</label>
                <div style={COMPOSER_ROW}>
                    <textarea
                        id="advisor-input"
                        rows={2}
                        maxLength={600}
                        value={draft}
                        placeholder={"Ask for a list, or say what to change…" if len(questions) > 0 else "Describe the list you want…"}
                        style={CONTROL | {"resize": "none"}}
                        onChange={lambda (e: any) { draft = e.target.value; }}
                        onKeyDown={on_key}
                    />
                    <button type="submit" style={PRIMARY} disabled={thinking or not draft.strip()}>Send</button>
                </div>
            </form>
        </div>
    </>
}
