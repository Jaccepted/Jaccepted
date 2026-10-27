"""My Colleges: the saved list as an application tracker.

Each college has a status, plan, deadline, checklist, notes and essay ideas.
Everything is stored on the saved item, so it syncs to the student's account
along with the list.
"""

import from "@jac/runtime" { Link }
import from .list_store { balance_warning, refresh_saved, store_saved }
import from .essays { EssayIdea, EssayResult, essay_ideas }
import from .components.nav { TopNav }
import from .components.spinner { Spinner }
import from .theme {
    BANNER,
    CARD,
    CONTROL,
    HINT,
    LEDE,
    LINK,
    PAGE,
    PRIMARY,
    SECONDARY,
    STACK,
    SUCCESS,
    TITLE,
    bucket_chip
}

glob STATUSES: list[list[str]] = [
    ["not_started", "Not started"],
    ["in_progress", "In progress"],
    ["submitted", "Submitted"],
    ["accepted", "Accepted"],
    ["waitlisted", "Waitlisted"],
    ["denied", "Not admitted"]
];

glob PLANS: list[list[str]] = [
    ["rd", "Regular Decision"],
    ["ea", "Early Action"],
    ["ed", "Early Decision"],
    ["rolling", "Rolling"]
];

glob TASKS: list[list[str]] = [
    ["essay", "Personal essay"],
    ["supplement", "Supplemental essays"],
    ["recs", "Recommendations requested"],
    ["scores", "Test scores sent"],
    ["transcript", "Transcript sent"],
    ["fee", "Fee paid or waived"]
];

glob MONTHS: list[str] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

glob NOTES_KEY: str = "jaccepted.essay_notes";

glob ROW_HEAD: dict[str, str] = {
    "display": "flex",
    "alignItems": "center",
    "flexWrap": "wrap",
    "gap": "0.5rem 0.9rem"
};

glob META: dict[str, str] = {
    "color": "var(--muted)",
    "fontSize": "0.9rem"
};

glob FIELD_LABEL: dict[str, str] = {
    "display": "block",
    "fontWeight": "600",
    "fontSize": "0.9rem",
    "marginBottom": "0.3rem"
};

glob IDEA_CARD: dict[str, str] = {
    "border": "1px solid var(--border)",
    "borderRadius": "12px",
    "padding": "0.8rem 0.9rem",
    "background": "var(--surface-2)"
};

def label_for(options: list[list[str]], key: str) -> str {
    for option in options {
        if option[0] == key {
            return option[1];
        }
    }
    return options[0][1];
}

def status_look(status: str) -> dict[str, str] {
    color = "var(--muted)";
    background = "var(--surface-3)";
    if status == "in_progress" or status == "waitlisted" {
        color = "var(--warn)";
        background = "var(--warn-bg)";
    } elif status == "submitted" or status == "accepted" {
        color = "var(--accent-text)";
        background = "var(--tint)";
    } elif status == "denied" {
        color = "var(--danger)";
        background = "var(--danger-bg)";
    }
    return {
        "minHeight": "36px",
        "padding": "0 0.6rem",
        "borderRadius": "999px",
        "border": "1px solid var(--border)",
        "background": background,
        "color": color,
        "font": "inherit",
        "fontWeight": "700",
        "fontSize": "0.85rem"
    };
}

"""The tracker fields for a saved college, with defaults for anything missing."""
def app_of(item: any) -> any {
    app: any = item["app"];
    if not app {
        app = {};
    }
    return {
        "status": app["status"] or "not_started",
        "plan": app["plan"] or "rd",
        "deadline": app["deadline"] or "",
        "tasks": app["tasks"] or [],
        "notes": app["notes"] or "",
        "ideas": app["ideas"] or [],
        "ideas_note": app["ideas_note"] or ""
    };
}

def item_with_app(item: any, app: any) -> dict[str, any] {
    return {
        "unitid": item["unitid"],
        "name": item["name"],
        "city": item["city"],
        "state": item["state"],
        "bucket": item["bucket"],
        "fit": item["fit"],
        "admit_rate": item["admit_rate"],
        "net_price": item["net_price"],
        "app": app
    };
}

def days_left(deadline: str) -> int {
    return int(Math.ceil((Date.parse(deadline + "T23:59:59") - Date.now()) / 86400000));
}

def nice_date(deadline: str) -> str {
    parts = deadline.split("-");
    if len(parts) != 3 {
        return deadline;
    }
    return MONTHS[int(parts[1]) - 1] + " " + str(int(parts[2])) + ", " + parts[0];
}

def due_text(deadline: str) -> str {
    if not deadline {
        return "No deadline set";
    }
    left = days_left(deadline);
    if left < 0 {
        return "Was due " + nice_date(deadline);
    }
    if left == 0 {
        return "Due today";
    }
    return "Due " + nice_date(deadline) + " · " + str(left) + (" day" if left == 1 else " days");
}

def deadline_order(item: any) -> str {
    deadline = app_of(item)["deadline"];
    return (deadline if deadline else "9999-99-99") + str(item["name"]);
}

def IdeaCard(idea: EssayIdea) -> JsxElement {
    <li style={IDEA_CARD}>
        <span style={{"display": "inline-block", "marginBottom": "0.3rem", "padding": "0.05rem 0.5rem", "borderRadius": "999px", "background": "var(--tint)", "color": "var(--accent-text)", "fontSize": "0.75rem", "fontWeight": "700"}}>{idea.essay_type}</span>
        <h4 style={{"margin": "0 0 0.25rem", "fontSize": "1rem"}}>{idea.title}</h4>
        <p style={{"margin": "0", "lineHeight": "1.5"}}>{idea.idea}</p>
        {len(idea.questions) > 0 and <ul style={{"margin": "0.45rem 0 0", "paddingLeft": "1.1rem", "color": "var(--muted)", "fontSize": "0.92rem"}}>
            {for question in idea.questions {
                <li key={question}>{question}</li>
            }}
        </ul>}
        {idea.avoid and <p style={{"margin": "0.45rem 0 0", "fontSize": "0.88rem", "color": "var(--warn)"}}>{"Avoid: " + idea.avoid}</p>}
    </li>
}

def:pub MyList -> JsxElement {
    has items: list[dict[str, any]] = [],
        open_id: str = "",
        essay_notes: str = "",
        loading_ideas: str = "",
        idea_error: str = "";

    async def load -> None {
        items = await refresh_saved();
        try {
            essay_notes = localStorage.getItem(NOTES_KEY) or "";
        } except Exception {
            essay_notes = "";
        }
    }

    can with entry {
        load();
    }

    def update(unitid: str, key: str, value: any, save: bool = True) -> None {
        changed: list[dict[str, any]] = [];
        for item in items {
            if item["unitid"] == unitid {
                app = app_of(item);
                app[key] = value;
                changed.append(item_with_app(item, app));
            } else {
                changed.append(item);
            }
        }
        items = changed;
        if save {
            store_saved(items);
        }
    }

    def toggle_task(item: any, task: str) -> None {
        done = app_of(item)["tasks"] as list[str];
        if task in done {
            update(item["unitid"] as str, "tasks", [kept for kept in done if kept != task]);
        } else {
            update(item["unitid"] as str, "tasks", done + [task]);
        }
    }

    def remove(unitid: str) -> None {
        items = [item for item in items if item["unitid"] != unitid];
        store_saved(items);
    }

    def save_notes -> None {
        try {
            localStorage.setItem(NOTES_KEY, essay_notes);
        } except Exception {
            return;
        }
    }

    def majors -> list[str] {
        try {
            raw = localStorage.getItem("jaccepted.intake");
            if raw {
                data: any = JSON.parse(raw);
                return [str(data[key]) for key in ["major1", "major2", "major3"] if data[key]];
            }
        } except Exception {
            return [];
        }
        return [];
    }

    async def find_ideas(unitid: str) -> None {
        if loading_ideas {
            return;
        }
        save_notes();
        loading_ideas = unitid;
        idea_error = "";
        result = EssayResult(ok=False, message="Essay ideas are unavailable right now.");
        try {
            result = await essay_ideas(unitid, majors(), essay_notes);
        } except Exception {
            result = EssayResult(ok=False, message="Essay ideas are unavailable right now.");
        }
        if result.ok {
            update(unitid, "ideas", result.ideas, False);
            update(unitid, "ideas_note", result.note);
        } else {
            idea_error = result.message;
        }
        loading_ideas = "";
    }

    warning = balance_warning(items);
    ordered = sorted(items, key=lambda (item: dict[str, any]) -> str { return deadline_order(item); });
    submitted = len([item for item in items if app_of(item)["status"] in ["submitted", "accepted", "waitlisted", "denied"]]);
    in_progress = len([item for item in items if app_of(item)["status"] == "in_progress"]);
    tasks_done = sum([len(app_of(item)["tasks"]) for item in items]);
    tasks_total = len(items) * len(TASKS);
    percent = round(100 * tasks_done / tasks_total) if tasks_total else 0;
    upcoming = [item for item in ordered if app_of(item)["deadline"] and days_left(app_of(item)["deadline"]) >= 0 and app_of(item)["status"] in ["not_started", "in_progress"]][:3];

    <>
        <TopNav current="my-list" saved_count={len(items)} />
        <div style={PAGE}>
            <header>
                <h1 style={TITLE}>My Colleges</h1>
                <p style={LEDE}>Track every application: status, deadline, checklist and essay ideas. Ask your advisor to fill gaps or rebalance the list.</p>
            </header>
            <main style={STACK}>
                {if len(items) == 0 {
                    <p style={HINT}>Nothing saved yet. Save colleges from <Link style={LINK} to="/advisor">your advisor</Link> or <Link style={LINK} to="/results">Explore</Link>.</p>
                } else {
                    <section style={CARD} data-glow="true" aria-label="Application summary">
                        <div style={{"display": "flex", "flexWrap": "wrap", "gap": "0.4rem 1.5rem", "alignItems": "baseline"}}>
                            <strong style={{"fontSize": "1.15rem"}}>{str(len(items)) + (" application" if len(items) == 1 else " applications")}</strong>
                            <span style={META}>{str(submitted) + " submitted · " + str(in_progress) + " in progress"}</span>
                        </div>
                        <div style={{"marginTop": "0.75rem"}} aria-label={"Checklist " + str(percent) + "% done"}>
                            <div style={{"height": "10px", "borderRadius": "999px", "background": "var(--surface-3)", "overflow": "hidden"}}>
                                <div style={{"height": "100%", "width": str(percent) + "%", "borderRadius": "999px", "background": "var(--accent)", "boxShadow": "var(--glow-strong)", "transition": "width 0.4s"}}></div>
                            </div>
                            <p style={HINT | {"marginTop": "0.35rem"}}>{str(tasks_done) + " of " + str(tasks_total) + " checklist items done"}</p>
                        </div>
                        <p style={(SUCCESS if not warning else BANNER) | {"margin": "0.6rem 0 0"}} role="status">
                            {warning if warning else "Your list is balanced across reach, target and likely."}
                        </p>
                        {len(upcoming) > 0 and <div style={{"marginTop": "0.8rem"}}>
                            <strong style={{"fontSize": "0.95rem"}}>Next deadlines</strong>
                            <ul style={{"listStyle": "none", "margin": "0.35rem 0 0", "padding": "0", "display": "flex", "flexDirection": "column", "gap": "0.25rem"}}>
                                {for item in upcoming {
                                    <li key={item["unitid"]} style={META}>
                                        <span style={{"color": "var(--text)", "fontWeight": "600"}}>{item["name"]}</span>
                                        {" · " + due_text(app_of(item)["deadline"])}
                                    </li>
                                }}
                            </ul>
                        </div>}
                    </section>
                }}
                {for item in ordered {
                    <section key={item["unitid"]} style={CARD | {"padding": "1rem 1.1rem"}} data-glow="true" aria-label={item["name"]}>
                        <div style={ROW_HEAD}>
                            <div style={{"flex": "1 1 16rem", "minWidth": "0"}}>
                                <span style={bucket_chip(item["bucket"])}>{item["bucket"]}</span>
                                <Link style={{"color": "var(--text)", "fontWeight": "700", "textDecoration": "none"}} to={"/college/" + item["unitid"]}>{item["name"]}</Link>
                                <div style={META}>
                                    {item["city"] + ", " + item["state"] + " · " + label_for(PLANS, app_of(item)["plan"]) + " · "}
                                    <span style={{"color": "var(--danger)"} if app_of(item)["deadline"] and days_left(app_of(item)["deadline"]) < 0 and app_of(item)["status"] in ["not_started", "in_progress"] else {}}>{due_text(app_of(item)["deadline"])}</span>
                                    {" · " + str(len(app_of(item)["tasks"])) + "/" + str(len(TASKS)) + " done"}
                                </div>
                            </div>
                            <label style={{"position": "absolute", "left": "-9999px"}} htmlFor={"status-" + item["unitid"]}>{"Status for " + item["name"]}</label>
                            <select
                                id={"status-" + item["unitid"]}
                                value={app_of(item)["status"]}
                                style={status_look(app_of(item)["status"])}
                                onChange={lambda (e: any) { update(item["unitid"] as str, "status", e.target.value); }}
                            >
                                {for status in STATUSES {
                                    <option key={status[0]} value={status[0]}>{status[1]}</option>
                                }}
                            </select>
                            <button
                                type="button"
                                style={SECONDARY | {"minHeight": "36px", "padding": "0 0.8rem"}}
                                aria-expanded={open_id == item["unitid"]}
                                onClick={lambda { open_id = "" if open_id == item["unitid"] else item["unitid"] as str; }}
                            >
                                {"Close" if open_id == item["unitid"] else "Open"}
                            </button>
                        </div>
                        {if open_id == item["unitid"] {
                            <div style={{"marginTop": "1rem", "display": "flex", "flexDirection": "column", "gap": "1rem", "animation": "jac-rise 0.2s ease-out"}}>
                                <div style={{"display": "grid", "gridTemplateColumns": "repeat(auto-fit, minmax(12rem, 1fr))", "gap": "0.8rem"}}>
                                    <div>
                                        <label style={FIELD_LABEL} htmlFor={"plan-" + item["unitid"]}>Application plan</label>
                                        <select id={"plan-" + item["unitid"]} value={app_of(item)["plan"]} style={CONTROL} onChange={lambda (e: any) { update(item["unitid"] as str, "plan", e.target.value); }}>
                                            {for plan in PLANS {
                                                <option key={plan[0]} value={plan[0]}>{plan[1]}</option>
                                            }}
                                        </select>
                                    </div>
                                    <div>
                                        <label style={FIELD_LABEL} htmlFor={"deadline-" + item["unitid"]}>Deadline</label>
                                        <input id={"deadline-" + item["unitid"]} type="date" value={app_of(item)["deadline"]} style={CONTROL} onChange={lambda (e: any) { update(item["unitid"] as str, "deadline", e.target.value); }} />
                                    </div>
                                </div>
                                <fieldset style={{"margin": "0", "padding": "0", "border": "0"}}>
                                    <legend style={FIELD_LABEL}>Checklist</legend>
                                    <div style={{"display": "grid", "gridTemplateColumns": "repeat(auto-fit, minmax(14rem, 1fr))", "gap": "0.4rem"}}>
                                        {for task in TASKS {
                                            <label key={task[0]} style={{"display": "flex", "alignItems": "center", "gap": "0.55rem", "minHeight": "40px", "padding": "0 0.6rem", "border": "1px solid var(--border)", "borderRadius": "10px", "background": "var(--tint)" if task[0] in app_of(item)["tasks"] else "var(--surface)", "cursor": "pointer"}}>
                                                <input type="checkbox" checked={task[0] in app_of(item)["tasks"]} onChange={lambda { toggle_task(item, task[0]); }} style={{"width": "1.1rem", "height": "1.1rem", "accentColor": "var(--accent)"}} />
                                                {task[1]}
                                            </label>
                                        }}
                                    </div>
                                </fieldset>
                                <div>
                                    <label style={FIELD_LABEL} htmlFor={"notes-" + item["unitid"]}>Notes</label>
                                    <textarea
                                        id={"notes-" + item["unitid"]}
                                        rows={2}
                                        value={app_of(item)["notes"]}
                                        placeholder="Portal login, interview date, things to ask…"
                                        style={CONTROL | {"resize": "vertical"}}
                                        onChange={lambda (e: any) { update(item["unitid"] as str, "notes", e.target.value, False); }}
                                        onBlur={lambda { store_saved(items); }}
                                    />
                                </div>
                                <section style={{"borderTop": "1px solid var(--border)", "paddingTop": "1rem"}} aria-label="Essay ideas">
                                    <h3 style={{"margin": "0", "fontSize": "1.05rem"}}>Essay ideas</h3>
                                    <p style={HINT | {"margin": "0.25rem 0 0.6rem"}}>
                                        Jot down a few experiences: activities, projects, challenges, things you care about. The AI coach suggests angles that connect them to this college. It never writes your essay; the words have to be yours.
                                    </p>
                                    <label style={FIELD_LABEL} htmlFor={"essay-notes-" + item["unitid"]}>Your experiences (shared across colleges)</label>
                                    <textarea
                                        id={"essay-notes-" + item["unitid"]}
                                        rows={4}
                                        maxLength={1500}
                                        value={essay_notes}
                                        placeholder="Robotics captain; rebuilt our arm before regionals. Tutor 8th graders in math. Started a school compost program."
                                        style={CONTROL | {"resize": "vertical"}}
                                        onChange={lambda (e: any) { essay_notes = e.target.value; }}
                                        onBlur={save_notes}
                                    />
                                    <div style={{"display": "flex", "alignItems": "center", "gap": "0.6rem", "marginTop": "0.6rem"}}>
                                        <button
                                            type="button"
                                            style={PRIMARY | {"display": "inline-flex", "alignItems": "center", "gap": "0.45rem"}}
                                            disabled={loading_ideas != ""}
                                            onClick={lambda { find_ideas(item["unitid"] as str); }}
                                        >
                                            {loading_ideas == item["unitid"] and <Spinner size={16} label="Finding ideas" />}
                                            {"Finding ideas…" if loading_ideas == item["unitid"] else ("New essay ideas" if len(app_of(item)["ideas"]) > 0 else "Find essay ideas")}
                                        </button>
                                    </div>
                                    {idea_error and loading_ideas == "" and <p style={BANNER} role="alert">{idea_error}</p>}
                                    {app_of(item)["ideas_note"] and <p style={HINT | {"marginTop": "0.6rem"}}>{app_of(item)["ideas_note"]}</p>}
                                    {len(app_of(item)["ideas"]) > 0 and <ul style={{"listStyle": "none", "padding": "0", "margin": "0.7rem 0 0", "display": "flex", "flexDirection": "column", "gap": "0.6rem"}}>
                                        {for idea in app_of(item)["ideas"] {
                                            <IdeaCard key={idea.title} idea={idea} />
                                        }}
                                    </ul>}
                                </section>
                                <div>
                                    <button type="button" style={SECONDARY} onClick={lambda { remove(item["unitid"] as str); }}>Remove from my list</button>
                                </div>
                            </div>
                        }}
                    </section>
                }}
            </main>
        </div>
    </>
}
