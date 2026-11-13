"""AI college list advisor.

A ByLLM agent that builds a college list from a student's request. It can only
recommend colleges the rule-based matcher returns for this student, and every
number it cites comes from these tools rather than from the model.
"""

import math;
import os;
import re;
import threading;
import time;
import uuid;
import from typing { Generator }
import from jaclang.byllm.lib { Model }
import from .matching {
    COLLEGES,
    MAX_WEIGHT,
    MAX_WEIGHT_CHANGES,
    MIN_WEIGHT,
    CollegeMatch,
    Profile,
    money,
    passing_colleges,
    percent,
    sanitize_weights
}
import from .ai_quota { LIMIT_MESSAGE, use_ai_request }

# The advisor's model. Tests swap in a MockLLM; JACCEPTED_MODEL overrides the
# default without a code change. The API key comes from ANTHROPIC_API_KEY.
glob advisor_llm: any = Model(model_name=os.environ.get("JACCEPTED_MODEL", "anthropic/claude-opus-5-5"));

glob MAX_REQUEST_CHARS: int = 600;
glob MAX_PICKS: int = 15;
glob TOOL_LIMIT: int = 15;
# Colleges per bucket handed to the agent up front, so a simple request needs no search.
glob STARTER_PER_BUCKET: int = 6;
glob BUCKETS: list[str] = ["reach", "target", "likely"];
glob DEFAULT_FOLLOW_UPS: list[str] = ["Add more likely schools", "Make the list cheaper", "Show only public colleges"];

glob BY_ID: dict[str, dict[str, any]] = {str(row["unitid"]): row for row in COLLEGES};

# Matches for each request in flight, keyed by request id. The model sees the
# id and tool results only, never the raw profile (ZIP, income, and so on).
glob SESSIONS: dict[str, list[CollegeMatch]] = {};

# The profile behind each request, so adjust_weights can re-score. Never shown to the model.
glob PROFILES: dict[str, Profile] = {};

# Plain names for the preferences the advisor can re-weight.
glob WEIGHT_LABELS: dict[str, str] = {
    "price": "cost", "location": "location", "distance": "distance", "setting": "campus setting",
    "size": "size", "type": "public/private", "outcomes": "graduation and earnings", "major": "your major"
};

# What the agent did on each request, in plain English, so the page can show its work.
glob STEPS: dict[str, list[str]] = {};

# When each request started, for the timing log.
glob STARTED: dict[str, float] = {};

# One successful re-weight per student message, so a tool loop cannot walk every preference to the cap.
glob WEIGHT_USED: dict[str, bool] = {};

def log_step(request_id: str, text: str) -> None {
    STEPS[request_id] = STEPS.get(request_id, []) + [text];
    print("advisor +" + str(round(time.perf_counter() - STARTED.get(request_id, time.perf_counter()), 1)) + "s:", text);
}

def join_labels(labels: list[str]) -> str {
    if len(labels) <= 1 {
        return labels[0] if labels else "";
    }
    if len(labels) == 2 {
        return labels[0] + " and " + labels[1];
    }
    text = "";
    for (index, label) in enumerate(labels) {
        if index == 0 {
            text = label;
        } elif index == len(labels) - 1 {
            text = text + ", and " + label;
        } else {
            text = text + ", " + label;
        }
    }
    return text;
}

"""What I did sentence, for example "Weighted cost higher than location." """
def weight_change_sentence(before: dict[str, float], after: dict[str, float]) -> str {
    order = ["price", "location", "distance", "setting", "size", "type", "outcomes", "major", "religion", "hbcu", "womens"];
    higher: list[str] = [];
    lower: list[str] = [];
    for key in order {
        prev = float(before.get(key, 1.0));
        nxt = float(after.get(key, 1.0));
        label = WEIGHT_LABELS.get(key, key);
        if nxt > prev + 0.001 {
            higher.append(label);
        } elif nxt < prev - 0.001 {
            lower.append(label);
        }
    }
    if len(higher) == 1 and len(lower) == 1 {
        return "Weighted " + higher[0] + " higher than " + lower[0] + ".";
    }
    parts: list[str] = [];
    if higher {
        parts.append("Weighted " + join_labels(higher) + " higher");
    }
    if lower {
        if parts {
            parts.append(join_labels(lower) + " lower");
        } else {
            parts.append("Weighted " + join_labels(lower) + " lower");
        }
    }
    if not parts {
        return "Weights stayed the same.";
    }
    return " and ".join(parts) + ".";
}

def top_cards(matches: list[CollegeMatch]) -> list[CollegeCard] {
    ranked_fit = sorted(matches, key=lambda (item: CollegeMatch) -> tuple[int, str] { return (-item.fit, item.name); });
    best: list[CollegeCard] = [];
    for name in BUCKETS {
        best = best + [card(item) for item in ranked_fit if item.bucket == name][:STARTER_PER_BUCKET];
    }
    return best;
}

"""One college as the advisor's tools describe it."""
obj CollegeCard {
    has unitid: str,
        name: str,
        location: str,
        region: str,
        kind: str,
        size: str,
        bucket: str,
        fit: int,
        admit_rate: str,
        net_price: str,
        miles: str,
        reasons: list[str] = [];
}
sem CollegeCard.unitid = "The college's ID. Use it exactly as given when recommending the college.";
sem CollegeCard.bucket = "reach, target, or likely: an estimate from public data, not an admission prediction.";
sem CollegeCard.fit = "0-100 score for how well the college matches the student's preferences.";
sem CollegeCard.net_price = "Average yearly cost after grants for the student's income bracket.";
sem CollegeCard.miles = "Distance from the student's home, or unknown.";
sem CollegeCard.reasons = "Facts behind the bucket and fit score.";

"""A college the advisor recommends."""
obj AdvisorPick {
    has unitid: str,
        why: str;
}
sem AdvisorPick.unitid = "The unitid of a college returned by find_colleges. Never invent one.";
sem AdvisorPick.why = "One standout reason this college suits the student, in under 20 words and with at most one number. Don't restate the reach/target/likely label; the page already shows it. For a college kept from the current list, say why it still fits rather than that it was kept.";

"""The advisor's answer."""
obj AdvisorPlan {
    has message: str,
        picks: list[AdvisorPick] = [],
        follow_ups: list[str] = [];
}
sem AdvisorPlan.message = "At most three short, plain-language sentences for the student: what you built or changed, and how the list is balanced. Keep numbers to a minimum, since the student can open any college for details. Don't mention tools or IDs.";
sem AdvisorPlan.picks = "The full recommended list, best first. When refining, include the colleges you keep from the current list.";
sem AdvisorPlan.follow_ups = "Two or three short next requests the student could tap to send, each under 8 words and written as the student would say them, for example 'Add more likely schools'. Not questions to the student.";

def card(item: CollegeMatch) -> CollegeCard {
    row = BY_ID.get(item.unitid, {});
    kind = "public" if row.get("control") == "public" else "private";
    return CollegeCard(
        unitid=item.unitid,
        name=item.name,
        location=item.city + ", " + item.state,
        region=str(row.get("region") or "unknown"),
        kind=kind,
        size=str(row.get("size_band") or "unknown"),
        bucket=item.bucket,
        fit=item.fit,
        admit_rate=(percent(item.admit_rate) if item.admit_rate is not None else "not published"),
        net_price=(money(float(item.net_price)) + "/yr" if item.net_price is not None else "not published"),
        miles=(str(item.miles) if item.miles is not None else "unknown"),
        reasons=item.reasons[:4]
    );
}

def missing_last(value: float | None) -> tuple[int, float] {
    if value is None {
        return (1, 0.0);
    }
    return (0, value);
}

obj Advisor {
    has request_id: str,
        current_list: list[CollegeCard] = [],
        starting_options: list[CollegeCard] = [];

    def matches -> list[CollegeMatch] {
        return SESSIONS.get(self.request_id, []);
    }

    def find_colleges(
        bucket: str,
        region: str,
        state: str,
        college_type: str,
        max_net_price: int,
        sort_by: str,
        limit: int
    ) -> list[CollegeCard] {
        items = self.matches();
        if bucket.lower() in BUCKETS {
            items = [item for item in items if item.bucket == bucket.lower()];
        }
        if region.strip() {
            items = [item for item in items if str(BY_ID.get(item.unitid, {}).get("region", "")).lower() == region.strip().lower()];
        }
        if state.strip() {
            items = [item for item in items if item.state.upper() == state.strip().upper()];
        }
        if college_type.lower() == "public" {
            items = [item for item in items if BY_ID.get(item.unitid, {}).get("control") == "public"];
        } elif college_type.lower() == "private" {
            items = [item for item in items if BY_ID.get(item.unitid, {}).get("control") != "public"];
        }
        if max_net_price > 0 {
            items = [item for item in items if item.net_price is not None and item.net_price <= max_net_price];
        }
        if sort_by == "price" {
            items = sorted(items, key=lambda (item: CollegeMatch) -> tuple[int, float] { return missing_last(item.net_price); });
        } elif sort_by == "admit" {
            items = sorted(items, key=lambda (item: CollegeMatch) -> tuple[int, float] { return missing_last(item.admit_rate); });
        } elif sort_by == "distance" {
            items = sorted(items, key=lambda (item: CollegeMatch) -> tuple[int, float] { return missing_last(item.miles); });
        } else {
            items = sorted(items, key=lambda (item: CollegeMatch) -> tuple[int, str] { return (-item.fit, item.name); });
        }
        count = max(1, min(limit, TOOL_LIMIT));
        if bucket.lower() not in BUCKETS {
            # One call covers all three buckets: up to `count` of each.
            mixed: list[CollegeMatch] = [];
            for name in BUCKETS {
                mixed = mixed + [item for item in items if item.bucket == name][:count];
            }
            found = len(items);
            items = mixed;
            count = len(mixed);
        } else {
            found = len(items);
        }
        filters = [part for part in [bucket.lower() if bucket.lower() in BUCKETS else "", region.strip(), state.strip().upper(), college_type.lower() if college_type.lower() in ["public", "private"] else ""] if part];
        described = " ".join(filters) + " colleges" if filters else "colleges";
        if max_net_price > 0 {
            described = described + " under " + money(float(max_net_price)) + " a year";
        }
        log_step(self.request_id, "Searched " + described + ": " + str(found) + " found.");
        return [card(item) for item in items[:count]];
    }

    def college_facts(unitid: str) -> str {
        found = [item for item in self.matches() if item.unitid == unitid.strip()];
        if not found {
            return "Not in this student's matches: it fails one of their must-haves, or the ID is wrong.";
        }
        item = found[0];
        log_step(self.request_id, "Looked into " + item.name + ".");
        row = BY_ID.get(item.unitid, {});
        lines = [
            item.name + " (" + item.city + ", " + item.state + "), " + item.bucket + ", fit " + str(item.fit) + ".",
            "Undergraduates: " + str(row.get("undergrad_enrollment") or "not published") + ".",
            "Admit rate: " + (percent(item.admit_rate) if item.admit_rate is not None else "not published") + "."
        ];
        if row.get("sat_reading_p25") and row.get("sat_math_p25") and row.get("sat_reading_p75") and row.get("sat_math_p75") {
            low = int(row["sat_reading_p25"]) + int(row["sat_math_p25"]);
            high = int(row["sat_reading_p75"]) + int(row["sat_math_p75"]);
            lines.append("SAT middle 50%: " + str(low) + "-" + str(high) + ".");
        }
        if row.get("grad_rate_6yr") is not None {
            lines.append("Six-year graduation rate: " + percent(float(row["grad_rate_6yr"])) + ".");
        }
        if row.get("earnings_10yr") is not None {
            lines.append("Median earnings 10 years after entry: " + money(float(row["earnings_10yr"])) + ".");
        }
        if item.net_price is not None {
            lines.append("Net price for this student's income bracket: " + money(float(item.net_price)) + " a year.");
        }
        return " ".join(lines + item.reasons);
    }

    def check_balance(unitids: list[str]) -> str {
        by_id = {item.unitid: item for item in self.matches()};
        known = [by_id[unitid] for unitid in unitids if unitid in by_id];
        unknown = [unitid for unitid in unitids if unitid not in by_id];
        counts = [str(len([item for item in known if item.bucket == bucket])) + " " + bucket for bucket in BUCKETS];
        text = ", ".join(counts) + ".";
        log_step(self.request_id, "Checked the balance: " + text);
        if unknown {
            text = text + " Not in this student's matches, so drop them: " + ", ".join(unknown) + ".";
        }
        return text;
    }

    def adjust_weights(
        price: float,
        location: float,
        distance: float,
        setting: float,
        size: float,
        college_type: float,
        outcomes: float,
        major: float
    ) -> list[CollegeCard] {
        profile = PROFILES[self.request_id];
        current = sanitize_weights(profile.weights);
        if WEIGHT_USED.get(self.request_id, False) {
            log_step(self.request_id, "Left your weights unchanged. They were already updated for this message.");
            return top_cards(self.matches());
        }
        asked = {"price": price, "location": location, "distance": distance, "setting": setting, "size": size, "type": college_type, "outcomes": outcomes, "major": major};
        proposed: dict[str, float] = dict(current);
        pending: list[str] = [];
        for (key, value) in asked.items() {
            number = float(value);
            # 1 means "leave this preference alone", so a full argument list cannot wipe the others.
            if not math.isfinite(number) or abs(number - 1.0) < 0.001 {
                continue;
            }
            factor = round(max(MIN_WEIGHT, min(MAX_WEIGHT, number)), 2);
            if abs(factor - float(current.get(key, 1.0))) < 0.001 {
                continue;
            }
            pending.append(key);
            proposed[key] = factor;
        }
        if len(pending) > MAX_WEIGHT_CHANGES {
            log_step(self.request_id, "Left your weights unchanged. Only 3 preferences can change at a time.");
            return top_cards(self.matches());
        }
        if len(pending) == 0 {
            return top_cards(self.matches());
        }
        profile.weights = sanitize_weights(proposed);
        SESSIONS[self.request_id] = passing_colleges(profile);
        WEIGHT_USED[self.request_id] = True;
        log_step(self.request_id, weight_change_sentence(current, profile.weights));
        return top_cards(SESSIONS[self.request_id]);
    }

    def plan(request: str) -> AdvisorPlan by advisor_llm(
        tools=[self.find_colleges, self.college_facts, self.check_balance, self.adjust_weights],
        max_react_iterations=12
    );
}

sem Advisor.find_colleges = "Search the colleges that already pass this student's must-haves. With an empty bucket, returns up to `limit` colleges from each of reach, target and likely in one call.";
sem Advisor.find_colleges.bucket = "reach, target or likely, or an empty string for all three at once.";
sem Advisor.find_colleges.region = "Northeast, Midwest, South, West, or an empty string for any region.";
sem Advisor.find_colleges.state = "Two-letter state code such as MI, or an empty string for any state.";
sem Advisor.find_colleges.college_type = "public, private, or an empty string for either.";
sem Advisor.find_colleges.max_net_price = "Maximum yearly net price in dollars, or 0 for no limit.";
sem Advisor.find_colleges.sort_by = "fit (best match first), price (cheapest first), admit (most selective first), or distance (closest first).";
sem Advisor.find_colleges.limit = "How many colleges to return (per bucket when bucket is empty), 1 to 15.";
sem Advisor.college_facts = "Extra details for one college (enrollment, SAT range, graduation rate, earnings). Only call it when the request needs a detail the cards don't have.";
sem Advisor.college_facts.unitid = "The college's unitid from find_colleges.";
sem Advisor.check_balance = "Count how many of the given colleges are reach, target and likely. Optional: the cards already show each college's bucket.";
sem Advisor.check_balance.unitids = "The unitids you plan to recommend.";
sem Advisor.plan = """Build or refine a college list for a high-school student from their request.
starting_options already holds the best-fitting colleges in each bucket, and current_list holds the student's list so far. If they cover the request, answer straight away without calling any tools.
When the student says one preference should matter more or less than another, call adjust_weights once before recommending. Pass 1 for every preference they did not mention. Never invent or change a fit score or a reach/target/likely bucket; the tool re-scores and re-buckets.
Call find_colleges only when the request needs something they don't cover, such as a state, region, price limit or sort order. One call with an empty bucket covers all three buckets.
Recommend only colleges from these lists or from find_colleges, by unitid.
Unless the student asks for something else, aim for 8 to 12 colleges with at least 2 likely and no more reach than target plus likely.
Mention only facts and numbers from the cards or tools.
Reach, target and likely are estimates from public data: never state a chance of admission or call any college a sure thing.""";
sem Advisor.plan.request = "What the student asked for, in their own words.";
sem Advisor.adjust_weights = "Change how much each preference counts in the fit score, when the student says something matters more or less. Re-scores every college from the matcher; you do not set fit scores. Pass 1 for anything they did not mention. At most 3 preferences per call, and only one call per message. Values are kept between 0.25 and 3.";
sem Advisor.adjust_weights.price = "Cost multiplier. 1 leaves it unchanged, 2 doubles it, 0.5 halves it. Kept between 0.25 and 3.";
sem Advisor.adjust_weights.location = "Region multiplier, same scale. 1 leaves it unchanged.";
sem Advisor.adjust_weights.distance = "Distance-from-home multiplier, same scale. 1 leaves it unchanged.";
sem Advisor.adjust_weights.setting = "Campus-setting multiplier, same scale. 1 leaves it unchanged.";
sem Advisor.adjust_weights.size = "Campus-size multiplier, same scale. 1 leaves it unchanged.";
sem Advisor.adjust_weights.college_type = "Public/private multiplier, same scale. 1 leaves it unchanged.";
sem Advisor.adjust_weights.outcomes = "Graduation and earnings multiplier, same scale. 1 leaves it unchanged.";
sem Advisor.adjust_weights.major = "Intended-major multiplier, same scale. 1 leaves it unchanged.";
sem Advisor.current_list = "The student's working list from earlier in the conversation. Keep these colleges unless the request asks to change them.";
sem Advisor.starting_options = "The best-fitting colleges in each bucket for this student, ready to recommend without a search.";

"""A recommended college with its data and the advisor's reason."""
obj AdvisorChoice {
    has unitid: str,
        name: str,
        city: str,
        state: str,
        bucket: str,
        fit: int,
        admit_rate: float | None = None,
        net_price: int | None = None,
        why: str = "";
}

"""What the advisor page shows."""
obj AdvisorResult {
    has ok: bool = True,
        message: str = "",
        picks: list[AdvisorChoice] = [],
        steps: list[str] = [],
        follow_ups: list[str] = [],
        weights: dict[str, float] = {},
        reach: int = 0,
        target: int = 0,
        likely: int = 0;
}

"""A pick's reason as one sentence, without a leading "Reach:" style label; the page shows the bucket."""
def clean_why(text: str) -> str {
    unlabeled = re.sub(r"^\s*(reach|target|likely)\s*[:.\-–—]\s*", "", text.strip(), flags=re.IGNORECASE);
    # One sentence: the college page has the rest.
    return re.split(r"(?<=[.!?])\s+", " ".join(unlabeled.split()))[0];
}

"""The advisor's message cut to three sentences, on one line: the picks carry the details."""
def short_message(text: str) -> str {
    sentences = re.split(r"(?<=[.!?])\s+", " ".join(text.split()));
    return " ".join(sentences[:3]);
}

"""Up to three tap-to-send requests. Questions to the student are dropped and defaults fill the gap."""
def clean_follow_ups(suggested: list[str]) -> list[str] {
    kept = [text.strip() for text in suggested if text.strip() and not text.strip().endswith("?") and len(text.strip()) <= 60];
    for text in DEFAULT_FOLLOW_UPS {
        if len(kept) >= 3 {
            break;
        }
        if text not in kept {
            kept.append(text);
        }
    }
    return kept[:3];
}

"""Keep only picks that are real matches for this student, once each, with our data."""
def grounded(plan: AdvisorPlan, matches: list[CollegeMatch]) -> AdvisorResult {
    by_id = {item.unitid: item for item in matches};
    picks: list[AdvisorChoice] = [];
    seen: list[str] = [];
    for pick in plan.picks {
        unitid = pick.unitid.strip();
        if unitid not in by_id or unitid in seen or len(picks) >= MAX_PICKS {
            continue;
        }
        seen.append(unitid);
        item = by_id[unitid];
        picks.append(AdvisorChoice(
            unitid=unitid,
            name=item.name,
            city=item.city,
            state=item.state,
            bucket=item.bucket,
            fit=item.fit,
            admit_rate=item.admit_rate,
            net_price=item.net_price,
            why=clean_why(pick.why)
        ));
    }
    return AdvisorResult(
        message=short_message(plan.message),
        picks=picks,
        follow_ups=clean_follow_ups(plan.follow_ups),
        reach=len([pick for pick in picks if pick.bucket == "reach"]),
        target=len([pick for pick in picks if pick.bucket == "target"]),
        likely=len([pick for pick in picks if pick.bucket == "likely"])
    );
}

def forget(request_id: str) -> None {
    SESSIONS.pop(request_id, None);
    STEPS.pop(request_id, None);
    STARTED.pop(request_id, None);
    PROFILES.pop(request_id, None);
    WEIGHT_USED.pop(request_id, None);
}

"""Set up a request: check it, find the student's matches, and count it against the daily cap.
Returns the request id and the kept current list, or a result to send back straight away.
Runs in the web request itself, because the daily cap is stored on the student's account."""
def prepare(question: str, profile: Profile, current_list: list[str]) -> tuple[str, list[str], AdvisorResult | None] {
    text = question.strip()[:MAX_REQUEST_CHARS];
    if not text {
        return ("", [], AdvisorResult(ok=False, message="Tell the advisor what kind of list you want."));
    }
    request_id = str(uuid.uuid4());
    STARTED[request_id] = time.perf_counter();
    profile.weights = sanitize_weights(profile.weights);
    PROFILES[request_id] = profile;
    SESSIONS[request_id] = passing_colleges(profile);
    if not SESSIONS[request_id] {
        forget(request_id);
        return ("", [], AdvisorResult(ok=False, message="No colleges pass your must-haves yet. Loosen one in your profile and try again."));
    }
    known = [item.unitid for item in SESSIONS[request_id]];
    keep = [unitid for unitid in current_list if unitid in known][:MAX_PICKS];
    # Counted only once the model is about to run, so refused requests are free.
    if not use_ai_request() {
        forget(request_id);
        return ("", [], AdvisorResult(ok=False, message=LIMIT_MESSAGE));
    }
    if keep {
        log_step(request_id, "Started from your current list of " + str(len(keep)) + (" college." if len(keep) == 1 else " colleges."));
    }
    return (request_id, keep, None);
}

"""Run the agent for a prepared request. Safe to run in a background thread."""
def run_advisor(request_id: str, question: str, keep: list[str]) -> AdvisorResult {
    try {
        profile = PROFILES[request_id];
        by_id = {item.unitid: item for item in SESSIONS[request_id]};
        ranked_fit = sorted(SESSIONS[request_id], key=lambda (item: CollegeMatch) -> tuple[int, str] { return (-item.fit, item.name); });
        starters: list[CollegeCard] = [];
        for name in BUCKETS {
            starters = starters + [card(item) for item in ranked_fit if item.bucket == name][:STARTER_PER_BUCKET];
        }
        log_step(request_id, "Reviewed your " + str(len(starters)) + " best-fitting options across reach, target and likely.");
        advisor = Advisor(request_id=request_id, current_list=[card(by_id[unitid]) for unitid in keep], starting_options=starters);
        result = grounded(advisor.plan(question.strip()[:MAX_REQUEST_CHARS]), SESSIONS[request_id]);
        log_step(request_id, "Checked the balance: " + str(result.reach) + " reach, " + str(result.target) + " target, " + str(result.likely) + " likely.");
        result.steps = STEPS.get(request_id, []);
        result.weights = dict(profile.weights) if profile.weights else {};
        return result;
    } except Exception as err {
        print("advisor failed:", type(err).__name__, err);
        return AdvisorResult(ok=False, message="The advisor is unavailable right now. Explore still works.");
    } finally {
        forget(request_id);
    }
}

"""Ask the advisor for a college list. Signed-in students only, with a daily cap, to keep AI costs in check.

The parameter is not called `request`: that name is taken by the web request on the server.
"""
def:protect ask_advisor(question: str, profile: Profile, current_list: list[str] = []) -> AdvisorResult {
    (request_id, keep, refused) = prepare(question, profile, current_list);
    if refused is not None {
        return refused;
    }
    return run_advisor(request_id, question, keep);
}

"""A result as plain JSON for the streaming endpoint."""
def result_json(result: AdvisorResult) -> dict[str, any] {
    return {
        "ok": result.ok,
        "message": result.message,
        "picks": [{"unitid": pick.unitid, "name": pick.name, "city": pick.city, "state": pick.state, "bucket": pick.bucket, "fit": pick.fit, "admit_rate": pick.admit_rate, "net_price": pick.net_price, "why": pick.why} for pick in result.picks],
        "steps": result.steps,
        "follow_ups": result.follow_ups,
        "weights": result.weights,
        "reach": result.reach,
        "target": result.target,
        "likely": result.likely
    };
}

"""Like ask_advisor, but streams each step the agent takes as it happens, then the answer.
Frames are {"step": "..."} and finally {"result": {...}}."""
def:protect ask_advisor_live(question: str, profile: Profile, current_list: list[str] = []) -> None {
    (request_id, keep, refused) = prepare(question, profile, current_list);

    def stream -> Generator[dict[str, any], None, None] {
        if refused is not None {
            yield {"result": result_json(refused)};
            return;
        }
        done: dict[str, AdvisorResult] = {};
        worker = threading.Thread(target=lambda { done["result"] = run_advisor(request_id, question, keep); }, daemon=True);
        worker.start();
        sent = 0;
        while worker.is_alive() {
            steps = STEPS.get(request_id, []);
            while sent < len(steps) {
                yield {"step": steps[sent]};
                sent = sent + 1;
            }
            time.sleep(0.25);
        }
        result = done.get("result", AdvisorResult(ok=False, message="The advisor is unavailable right now. Explore still works."));
        while sent < len(result.steps) {
            yield {"step": result.steps[sent]};
            sent = sent + 1;
        }
        yield {"result": result_json(result)};
    }
    report stream();
}
