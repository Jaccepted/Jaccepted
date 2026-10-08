"""Profile intake wizard.

Collects the MVP profile: academics, test scores, up to three majors, and
core campus, cost, and home preferences. The draft stays in this browser.
"""

import from .components.fields { CheckField, Importance, RadioLine, SelectField, TextField }
import from .majors { MAJOR_NAMES }
import from .intake_rules {
    academics_error,
    campus_error,
    cost_error,
    importance_label,
    join_csv,
    join_labels,
    show,
    tests_error
}
import "./styles/intake.css";

glob STATES: list[str] = [
    "Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado",
    "Connecticut", "Delaware", "District of Columbia", "Florida", "Georgia",
    "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky",
    "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota",
    "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire",
    "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota",
    "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina",
    "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia",
    "Washington", "West Virginia", "Wisconsin", "Wyoming"
];

glob GRAD_YEARS: list[str] = ["2026", "2027", "2028", "2029", "2030", "2031", "2032"];

glob INCOME: list[list[str]] = [
    ["0-30000", "$0 – $30,000"],
    ["30001-48000", "$30,001 – $48,000"],
    ["48001-75000", "$48,001 – $75,000"],
    ["75001-110000", "$75,001 – $110,000"],
    ["110001+", "$110,001 or more"]
];

def take(data: any, key: str, fallback: str) -> str {
    saved = data[key];
    if saved {
        return saved as str;
    }
    return fallback;
}

def:pub IntakeForm -> JsxElement {
    has step: str = "0",
        finished: str = "no",
        error: str = "",
        gpa_unweighted: str = "",
        gpa_weighted: str = "",
        gpa_scale: str = "4.0",
        class_percentile: str = "",
        class_rank: str = "",
        class_size: str = "",
        ap_count: str = "",
        ib_count: str = "",
        honors_count: str = "",
        dual_count: str = "",
        grad_year: str = "",
        test_plan: str = "none",
        sat_total: str = "",
        sat_reading: str = "",
        sat_math: str = "",
        act_composite: str = "",
        act_english: str = "",
        act_math: str = "",
        act_reading: str = "",
        act_science: str = "",
        undecided: str = "no",
        major1: str = "",
        major2: str = "",
        major3: str = "",
        regions: str = "",
        location_importance: str = "ignore",
        setting: str = "",
        setting_importance: str = "ignore",
        distance: str = "",
        distance_importance: str = "ignore",
        size_small: str = "yes",
        size_medium: str = "yes",
        size_large: str = "yes",
        size_importance: str = "ignore",
        want_public: str = "yes",
        want_private: str = "yes",
        control_importance: str = "ignore",
        religious: str = "",
        religious_importance: str = "ignore",
        want_hbcu: str = "no",
        hbcu_importance: str = "ignore",
        want_womens: str = "no",
        womens_importance: str = "ignore",
        max_price: str = "",
        price_importance: str = "ignore",
        outcomes_importance: str = "ignore",
        income_bracket: str = "",
        home_state: str = "",
        home_zip: str = "",
        first_gen: str = "";

    def remember -> None {
        try {
            localStorage.setItem("jaccepted.intake", JSON.stringify({
                "step": step,
                "finished": finished,
                "gpa_unweighted": gpa_unweighted,
                "gpa_weighted": gpa_weighted,
                "gpa_scale": gpa_scale,
                "class_percentile": class_percentile,
                "class_rank": class_rank,
                "class_size": class_size,
                "ap_count": ap_count,
                "ib_count": ib_count,
                "honors_count": honors_count,
                "dual_count": dual_count,
                "grad_year": grad_year,
                "test_plan": test_plan,
                "sat_total": sat_total,
                "sat_reading": sat_reading,
                "sat_math": sat_math,
                "act_composite": act_composite,
                "act_english": act_english,
                "act_math": act_math,
                "act_reading": act_reading,
                "act_science": act_science,
                "undecided": undecided,
                "major1": major1,
                "major2": major2,
                "major3": major3,
                "regions": regions,
                "location_importance": location_importance,
                "setting": setting,
                "setting_importance": setting_importance,
                "distance": distance,
                "distance_importance": distance_importance,
                "size_small": size_small,
                "size_medium": size_medium,
                "size_large": size_large,
                "size_importance": size_importance,
                "want_public": want_public,
                "want_private": want_private,
                "control_importance": control_importance,
                "religious": religious,
                "religious_importance": religious_importance,
                "want_hbcu": want_hbcu,
                "hbcu_importance": hbcu_importance,
                "want_womens": want_womens,
                "womens_importance": womens_importance,
                "max_price": max_price,
                "price_importance": price_importance,
                "outcomes_importance": outcomes_importance,
                "income_bracket": income_bracket,
                "home_state": home_state,
                "home_zip": home_zip,
                "first_gen": first_gen
            }));
        } except Exception {
            return;
        }
    }

    def load_draft -> None {
        raw = localStorage.getItem("jaccepted.intake");
        if not raw {
            return;
        }
        try {
            data = JSON.parse(raw);
            loaded_step = take(data, "step", "0");
            if loaded_step not in ["0", "1", "2", "3", "4", "5"] {
                loaded_step = "0";
            }
            step = loaded_step;
            finished = take(data, "finished", "no");
            gpa_unweighted = take(data, "gpa_unweighted", "");
            gpa_weighted = take(data, "gpa_weighted", "");
            gpa_scale = take(data, "gpa_scale", "4.0");
            class_percentile = take(data, "class_percentile", "");
            class_rank = take(data, "class_rank", "");
            class_size = take(data, "class_size", "");
            ap_count = take(data, "ap_count", "");
            ib_count = take(data, "ib_count", "");
            honors_count = take(data, "honors_count", "");
            dual_count = take(data, "dual_count", "");
            grad_year = take(data, "grad_year", "");
            test_plan = take(data, "test_plan", "none");
            sat_total = take(data, "sat_total", "");
            sat_reading = take(data, "sat_reading", "");
            sat_math = take(data, "sat_math", "");
            act_composite = take(data, "act_composite", "");
            act_english = take(data, "act_english", "");
            act_math = take(data, "act_math", "");
            act_reading = take(data, "act_reading", "");
            act_science = take(data, "act_science", "");
            undecided = take(data, "undecided", "no");
            major1 = take(data, "major1", "");
            major2 = take(data, "major2", "");
            major3 = take(data, "major3", "");
            regions = take(data, "regions", "");
            location_importance = take(data, "location_importance", "ignore");
            setting = take(data, "setting", "");
            setting_importance = take(data, "setting_importance", "ignore");
            distance = take(data, "distance", "");
            distance_importance = take(data, "distance_importance", "ignore");
            size_small = take(data, "size_small", "yes");
            size_medium = take(data, "size_medium", "yes");
            size_large = take(data, "size_large", "yes");
            size_importance = take(data, "size_importance", "ignore");
            want_public = take(data, "want_public", "yes");
            want_private = take(data, "want_private", "yes");
            control_importance = take(data, "control_importance", "ignore");
            religious = take(data, "religious", "");
            religious_importance = take(data, "religious_importance", "ignore");
            want_hbcu = take(data, "want_hbcu", "no");
            hbcu_importance = take(data, "hbcu_importance", "ignore");
            want_womens = take(data, "want_womens", "no");
            womens_importance = take(data, "womens_importance", "ignore");
            max_price = take(data, "max_price", "");
            price_importance = take(data, "price_importance", "ignore");
            outcomes_importance = take(data, "outcomes_importance", "ignore");
            income_bracket = take(data, "income_bracket", "");
            home_state = take(data, "home_state", "");
            home_zip = take(data, "home_zip", "");
            first_gen = take(data, "first_gen", "");
        } except Exception {
            return;
        }
    }

    can with entry {
        load_draft();
    }

    def region_on(name: str) -> bool {
        return name in [part for part in regions.split(",") if part];
    }

    def set_region(name: str, on: bool) -> None {
        parts = [part for part in regions.split(",") if part];
        if on {
            if name not in parts {
                parts = parts + [name];
            }
        } else {
            parts = [part for part in parts if part != name];
        }
        regions = join_csv(parts);
        error = "";
        remember();
    }

    def yes_no(on: bool) -> str {
        if on {
            return "yes";
        }
        return "no";
    }

    def current_academics_error -> str {
        return academics_error(
            gpa_unweighted,
            gpa_weighted,
            gpa_scale,
            class_percentile,
            class_rank,
            class_size,
            ap_count,
            ib_count,
            honors_count,
            dual_count,
            grad_year
        );
    }

    def current_tests_error -> str {
        return tests_error(
            test_plan,
            sat_total,
            sat_reading,
            sat_math,
            act_composite,
            act_english,
            act_math,
            act_reading,
            act_science
        );
    }

    def current_campus_error -> str {
        return campus_error(
            distance,
            size_small,
            size_medium,
            size_large,
            want_public,
            want_private
        );
    }

    def go_to(index: str) -> None {
        error = "";
        step = index;
        remember();
    }

    def next_step -> None {
        message = "";
        if step == "0" {
            message = current_academics_error();
        } elif step == "1" {
            message = current_tests_error();
        } elif step == "3" {
            message = current_campus_error();
        } elif step == "4" {
            message = cost_error(max_price, home_zip);
        }
        if message {
            error = message;
            return;
        }
        error = "";
        if step == "5" {
            finished = "yes";
            remember();
            return;
        }
        step = str(int(step) + 1);
        remember();
    }

    def prev_step -> None {
        error = "";
        if int(step) > 0 {
            step = str(int(step) - 1);
            remember();
        }
    }

    def reset_profile -> None {
        try {
            localStorage.removeItem("jaccepted.intake");
        } except Exception {
            error = "";
        }
        step = "0";
        finished = "no";
        error = "";
        gpa_unweighted = "";
        gpa_weighted = "";
        gpa_scale = "4.0";
        class_percentile = "";
        class_rank = "";
        class_size = "";
        ap_count = "";
        ib_count = "";
        honors_count = "";
        dual_count = "";
        grad_year = "";
        test_plan = "none";
        sat_total = "";
        sat_reading = "";
        sat_math = "";
        act_composite = "";
        act_english = "";
        act_math = "";
        act_reading = "";
        act_science = "";
        undecided = "no";
        major1 = "";
        major2 = "";
        major3 = "";
        regions = "";
        location_importance = "ignore";
        setting = "";
        setting_importance = "ignore";
        distance = "";
        distance_importance = "ignore";
        size_small = "yes";
        size_medium = "yes";
        size_large = "yes";
        size_importance = "ignore";
        want_public = "yes";
        want_private = "yes";
        control_importance = "ignore";
        religious = "";
        religious_importance = "ignore";
        want_hbcu = "no";
        hbcu_importance = "ignore";
        want_womens = "no";
        womens_importance = "ignore";
        max_price = "";
        price_importance = "ignore";
        outcomes_importance = "ignore";
        income_bracket = "";
        home_state = "";
        home_zip = "";
        first_gen = "";
    }

    def step_class(index: str) -> str {
        if index == step {
            return "step-btn current";
        }
        if int(index) < int(step) {
            return "step-btn done";
        }
        return "step-btn";
    }

    def step_current(index: str) -> str {
        if index == step {
            return "step";
        }
        return "false";
    }

    def size_summary -> str {
        labels: list[str] = [];
        if size_small == "yes" {
            labels = labels + ["Small (under 5,000)"];
        }
        if size_medium == "yes" {
            labels = labels + ["Medium (5,000–15,000)"];
        }
        if size_large == "yes" {
            labels = labels + ["Large (over 15,000)"];
        }
        return join_labels(labels, "No size selected");
    }

    def control_summary -> str {
        labels: list[str] = [];
        if want_public == "yes" {
            labels = labels + ["Public"];
        }
        if want_private == "yes" {
            labels = labels + ["Private"];
        }
        return join_labels(labels, "None selected");
    }

    def region_summary -> str {
        return join_labels([part for part in regions.split(",") if part], "Anywhere in the US");
    }

    def setting_summary -> str {
        if setting == "urban" {
            return "Urban";
        }
        if setting == "suburban" {
            return "Suburban";
        }
        if setting == "rural" {
            return "Rural";
        }
        return "No preference";
    }

    def religious_summary -> str {
        if religious == "religious" {
            return "Prefer a religiously affiliated college";
        }
        if religious == "secular" {
            return "Prefer a college that is not religiously affiliated";
        }
        return "No preference";
    }

    def income_summary -> str {
        if income_bracket == "0-30000" {
            return "$0 – $30,000";
        }
        if income_bracket == "30001-48000" {
            return "$30,001 – $48,000";
        }
        if income_bracket == "48001-75000" {
            return "$48,001 – $75,000";
        }
        if income_bracket == "75001-110000" {
            return "$75,001 – $110,000";
        }
        if income_bracket == "110001+" {
            return "$110,001 or more";
        }
        return "Not provided";
    }

    def first_gen_summary -> str {
        if first_gen == "yes" {
            return "Yes";
        }
        if first_gen == "no" {
            return "No";
        }
        if first_gen == "skip" {
            return "Prefer not to say";
        }
        return "Not provided";
    }

    def rigor_summary -> str {
        labels: list[str] = [];
        if ap_count.strip() {
            labels = labels + ["AP " + ap_count.strip()];
        }
        if ib_count.strip() {
            labels = labels + ["IB " + ib_count.strip()];
        }
        if honors_count.strip() {
            labels = labels + ["Honors " + honors_count.strip()];
        }
        if dual_count.strip() {
            labels = labels + ["Dual-enrollment " + dual_count.strip()];
        }
        return join_labels(labels, "Not provided");
    }

    def majors_summary -> str {
        if undecided == "yes" {
            return "Undecided";
        }
        majors = [major.strip() for major in [major1, major2, major3] if major.strip()];
        return join_labels(majors, "Not provided");
    }

    def test_summary -> str {
        if test_plan == "sat" {
            return "SAT " + show(sat_total);
        }
        if test_plan == "act" {
            return "ACT " + show(act_composite);
        }
        return "Not submitting scores";
    }

    def review_item(label: str, value: str) -> JsxElement {
        <><dt>{label}</dt><dd>{value}</dd></>
    }

    title = "Academics";
    copy = "Unweighted GPA and graduation year are required. Everything else can wait.";
    if step == "1" {
        title = "Test scores";
        copy = "Share an SAT or ACT if you plan to submit one. Sections are optional.";
    } elif step == "2" {
        title = "Intended major";
        copy = "Pick a suggested major when it fits, or type your own. You can also say you are undecided.";
    } elif step == "3" {
        title = "Campus preferences";
        copy = "Mark what you want in a campus, and how important each part is.";
    } elif step == "4" {
        title = "Cost and home";
        copy = "Home ZIP is used for distance. Income is used for net price. Earnings are a preference, not a promise.";
    } elif step == "5" {
        title = "Review your profile";
        copy = "This is an estimate profile for matching. It is not an admission decision.";
    }

    <div className="page">
        <header>
            <p className="eyebrow">College list</p>
            <h1>Jaccepted</h1>
            <p className="lede">
                Tell us about your academics and what you want in a college. Matching uses this profile later. Nothing here predicts admission.
            </p>
        </header>
        <main>
            <ol className="steps" aria-label="Intake steps">
                <li>
                    <button type="button" className={step_class("0")} aria-current={step_current("0")} onClick={lambda { go_to("0"); }}>
                        Academics
                    </button>
                </li>
                <li>
                    <button type="button" className={step_class("1")} aria-current={step_current("1")} onClick={lambda { go_to("1"); }}>
                        Tests
                    </button>
                </li>
                <li>
                    <button type="button" className={step_class("2")} aria-current={step_current("2")} onClick={lambda { go_to("2"); }}>
                        Major
                    </button>
                </li>
                <li>
                    <button type="button" className={step_class("3")} aria-current={step_current("3")} onClick={lambda { go_to("3"); }}>
                        Campus
                    </button>
                </li>
                <li>
                    <button type="button" className={step_class("4")} aria-current={step_current("4")} onClick={lambda { go_to("4"); }}>
                        Cost
                    </button>
                </li>
                <li>
                    <button type="button" className={step_class("5")} aria-current={step_current("5")} onClick={lambda { go_to("5"); }}>
                        Review
                    </button>
                </li>
            </ol>
            <section className="card" aria-labelledby="step-title">
                <h2 id="step-title">{title}</h2>
                <p className="step-copy">{copy}</p>
                {error and <p className="banner" role="alert">{error}</p>}
                {finished == "yes" and step == "5" and <p className="success" role="status">Profile saved in this browser. You can keep editing it on this device.</p>}
                {if step == "0" {
                    <div className="stack">
                        <TextField
                            id="gpa-unweighted"
                            label="Unweighted GPA"
                            value={gpa_unweighted}
                            onValue={lambda (value: str) { gpa_unweighted = value; error = ""; remember(); }}
                            required={True}
                            hint="Use the unweighted number from your transcript."
                            placeholder="3.7"
                            input_mode="decimal"
                        />
                        <TextField
                            id="gpa-weighted"
                            label="Weighted GPA"
                            value={gpa_weighted}
                            onValue={lambda (value: str) { gpa_weighted = value; error = ""; remember(); }}
                            hint="Leave blank if your school does not weight grades."
                            placeholder="4.2"
                            input_mode="decimal"
                        />
                        <fieldset>
                            <legend className="group-legend">GPA scale</legend>
                            <div className="choices">
                                <RadioLine name="gpa-scale" value="4.0" current={gpa_scale} label="4.0" onValue={lambda (value: str) { gpa_scale = value; error = ""; remember(); }} />
                                <RadioLine name="gpa-scale" value="5.0" current={gpa_scale} label="5.0" onValue={lambda (value: str) { gpa_scale = value; error = ""; remember(); }} />
                                <RadioLine name="gpa-scale" value="100" current={gpa_scale} label="100" onValue={lambda (value: str) { gpa_scale = value; error = ""; remember(); }} />
                            </div>
                        </fieldset>
                        <div className="grid-2">
                            <TextField
                                id="class-percentile"
                                label="Class percentile"
                                value={class_percentile}
                                onValue={lambda (value: str) { class_percentile = value; error = ""; remember(); }}
                                hint="Enter 10 if you are in the top 10%."
                                placeholder="10"
                                input_mode="numeric"
                            />
                            <SelectField
                                id="grad-year"
                                label="Graduation year"
                                value={grad_year}
                                onValue={lambda (value: str) { grad_year = value; error = ""; remember(); }}
                                required={True}
                                hint="The year you finish high school."
                            >
                                <option value="">Select a year</option>
                                {for year in GRAD_YEARS {
                                    <option key={year} value={year}>{year}</option>
                                }}
                            </SelectField>
                            <TextField
                                id="class-rank"
                                label="Class rank"
                                value={class_rank}
                                onValue={lambda (value: str) { class_rank = value; error = ""; remember(); }}
                                hint="Your place in the class. 1 is the top student."
                                placeholder="25"
                                input_mode="numeric"
                            />
                            <TextField
                                id="class-size"
                                label="Class size"
                                value={class_size}
                                onValue={lambda (value: str) { class_size = value; error = ""; remember(); }}
                                hint="How many students are in your graduating class."
                                placeholder="400"
                                input_mode="numeric"
                            />
                        </div>
                        <fieldset>
                            <legend className="group-legend">Course rigor</legend>
                            <div className="grid-2">
                                <TextField id="ap-count" label="AP courses" value={ap_count} onValue={lambda (value: str) { ap_count = value; error = ""; remember(); }} placeholder="4" input_mode="numeric" />
                                <TextField id="ib-count" label="IB courses" value={ib_count} onValue={lambda (value: str) { ib_count = value; error = ""; remember(); }} placeholder="0" input_mode="numeric" />
                                <TextField id="honors-count" label="Honors courses" value={honors_count} onValue={lambda (value: str) { honors_count = value; error = ""; remember(); }} placeholder="6" input_mode="numeric" />
                                <TextField id="dual-count" label="Dual-enrollment courses" value={dual_count} onValue={lambda (value: str) { dual_count = value; error = ""; remember(); }} placeholder="1" input_mode="numeric" />
                            </div>
                        </fieldset>
                    </div>
                }}
                {if step == "1" {
                    <div className="stack">
                        <fieldset>
                            <legend className="group-legend">What do you plan to submit?</legend>
                            <div className="choices">
                                <RadioLine name="test-plan" value="sat" current={test_plan} label="SAT" onValue={lambda (value: str) { test_plan = value; error = ""; remember(); }} />
                                <RadioLine name="test-plan" value="act" current={test_plan} label="ACT" onValue={lambda (value: str) { test_plan = value; error = ""; remember(); }} />
                                <RadioLine name="test-plan" value="none" current={test_plan} label="Not submitting" onValue={lambda (value: str) { test_plan = value; error = ""; remember(); }} />
                            </div>
                        </fieldset>
                        {if test_plan == "sat" {
                            <div className="grid-2">
                                <TextField id="sat-total" label="SAT total" value={sat_total} onValue={lambda (value: str) { sat_total = value; error = ""; remember(); }} required={True} hint="400 to 1600." placeholder="1420" input_mode="numeric" />
                                <TextField id="sat-reading" label="SAT reading and writing" value={sat_reading} onValue={lambda (value: str) { sat_reading = value; error = ""; remember(); }} hint="200 to 800." placeholder="710" input_mode="numeric" />
                                <TextField id="sat-math" label="SAT math" value={sat_math} onValue={lambda (value: str) { sat_math = value; error = ""; remember(); }} hint="200 to 800." placeholder="710" input_mode="numeric" />
                            </div>
                        }}
                        {if test_plan == "act" {
                            <div className="grid-2">
                                <TextField id="act-composite" label="ACT composite" value={act_composite} onValue={lambda (value: str) { act_composite = value; error = ""; remember(); }} required={True} hint="1 to 36." placeholder="32" input_mode="numeric" />
                                <TextField id="act-english" label="ACT English" value={act_english} onValue={lambda (value: str) { act_english = value; error = ""; remember(); }} placeholder="33" input_mode="numeric" />
                                <TextField id="act-math" label="ACT math" value={act_math} onValue={lambda (value: str) { act_math = value; error = ""; remember(); }} placeholder="31" input_mode="numeric" />
                                <TextField id="act-reading" label="ACT reading" value={act_reading} onValue={lambda (value: str) { act_reading = value; error = ""; remember(); }} placeholder="34" input_mode="numeric" />
                                <TextField id="act-science" label="ACT science" value={act_science} onValue={lambda (value: str) { act_science = value; error = ""; remember(); }} placeholder="30" input_mode="numeric" />
                            </div>
                        }}
                    </div>
                }}
                {if step == "2" {
                    <div className="stack">
                        <CheckField
                            id="undecided"
                            label="I am undecided"
                            checked={undecided == "yes"}
                            onChecked={lambda (on: bool) { undecided = yes_no(on); error = ""; remember(); }}
                        />
                        <TextField id="major-1" label="First major or area" value={major1} onValue={lambda (value: str) { major1 = value; error = ""; remember(); }} placeholder="Computer Science" disabled={undecided == "yes"} suggestions={MAJOR_NAMES} hint="Suggested names match college programs. Another name is still saved." />
                        <TextField id="major-2" label="Second major or area" value={major2} onValue={lambda (value: str) { major2 = value; error = ""; remember(); }} placeholder="Biology" disabled={undecided == "yes"} suggestions={MAJOR_NAMES} />
                        <TextField id="major-3" label="Third major or area" value={major3} onValue={lambda (value: str) { major3 = value; error = ""; remember(); }} placeholder="Economics" disabled={undecided == "yes"} suggestions={MAJOR_NAMES} />
                    </div>
                }}
                {if step == "3" {
                    <div className="stack">
                        <fieldset>
                            <legend className="group-legend">Regions</legend>
                            <p className="hint">Leave these unchecked if you are open to anywhere in the US.</p>
                            <div className="checks">
                                <CheckField id="region-northeast" label="Northeast" checked={region_on("Northeast")} onChecked={lambda (on: bool) { set_region("Northeast", on); }} />
                                <CheckField id="region-midwest" label="Midwest" checked={region_on("Midwest")} onChecked={lambda (on: bool) { set_region("Midwest", on); }} />
                                <CheckField id="region-south" label="South" checked={region_on("South")} onChecked={lambda (on: bool) { set_region("South", on); }} />
                                <CheckField id="region-west" label="West" checked={region_on("West")} onChecked={lambda (on: bool) { set_region("West", on); }} />
                            </div>
                            <Importance name="location-importance" value={location_importance} onValue={lambda (value: str) { location_importance = value; error = ""; remember(); }} />
                        </fieldset>
                        <SelectField
                            id="setting"
                            label="Campus setting"
                            value={setting}
                            onValue={lambda (value: str) { setting = value; error = ""; remember(); }}
                            hint="City, suburb, or a smaller town."
                        >
                            <option value="">No preference</option>
                            <option value="urban">Urban</option>
                            <option value="suburban">Suburban</option>
                            <option value="rural">Rural</option>
                        </SelectField>
                        <Importance name="setting-importance" value={setting_importance} onValue={lambda (value: str) { setting_importance = value; error = ""; remember(); }} />
                        <TextField
                            id="distance"
                            label="Maximum distance from home"
                            value={distance}
                            onValue={lambda (value: str) { distance = value; error = ""; remember(); }}
                            hint="Miles from your home ZIP. Leave blank if distance does not matter."
                            placeholder="300"
                            input_mode="decimal"
                        />
                        <Importance name="distance-importance" value={distance_importance} onValue={lambda (value: str) { distance_importance = value; error = ""; remember(); }} />
                        <fieldset>
                            <legend className="group-legend">Campus size</legend>
                            <div className="checks">
                                <CheckField id="size-small" label="Small, under 5,000" checked={size_small == "yes"} onChecked={lambda (on: bool) { size_small = yes_no(on); error = ""; remember(); }} />
                                <CheckField id="size-medium" label="Medium, 5,000 to 15,000" checked={size_medium == "yes"} onChecked={lambda (on: bool) { size_medium = yes_no(on); error = ""; remember(); }} />
                                <CheckField id="size-large" label="Large, over 15,000" checked={size_large == "yes"} onChecked={lambda (on: bool) { size_large = yes_no(on); error = ""; remember(); }} />
                            </div>
                            <Importance name="size-importance" value={size_importance} onValue={lambda (value: str) { size_importance = value; error = ""; remember(); }} />
                        </fieldset>
                        <fieldset>
                            <legend className="group-legend">College type</legend>
                            <div className="checks">
                                <CheckField id="want-public" label="Public" checked={want_public == "yes"} onChecked={lambda (on: bool) { want_public = yes_no(on); error = ""; remember(); }} />
                                <CheckField id="want-private" label="Private" checked={want_private == "yes"} onChecked={lambda (on: bool) { want_private = yes_no(on); error = ""; remember(); }} />
                            </div>
                            <Importance name="control-importance" value={control_importance} onValue={lambda (value: str) { control_importance = value; error = ""; remember(); }} />
                        </fieldset>
                        <SelectField
                            id="religious"
                            label="Religious affiliation"
                            value={religious}
                            onValue={lambda (value: str) { religious = value; error = ""; remember(); }}
                        >
                            <option value="">No preference</option>
                            <option value="religious">Prefer a religiously affiliated college</option>
                            <option value="secular">Prefer a college that is not religiously affiliated</option>
                        </SelectField>
                        <Importance name="religious-importance" value={religious_importance} onValue={lambda (value: str) { religious_importance = value; error = ""; remember(); }} />
                        <CheckField id="want-hbcu" label="I want to consider HBCUs" checked={want_hbcu == "yes"} onChecked={lambda (on: bool) { want_hbcu = yes_no(on); error = ""; remember(); }} />
                        <Importance name="hbcu-importance" value={hbcu_importance} onValue={lambda (value: str) { hbcu_importance = value; error = ""; remember(); }} />
                        <CheckField id="want-womens" label="I want to consider women's colleges" checked={want_womens == "yes"} onChecked={lambda (on: bool) { want_womens = yes_no(on); error = ""; remember(); }} />
                        <p className="hint">Women's colleges are the members of the Women's College Coalition.</p>
                        <Importance name="womens-importance" value={womens_importance} onValue={lambda (value: str) { womens_importance = value; error = ""; remember(); }} />
                    </div>
                }}
                {if step == "4" {
                    <div className="stack">
                        <TextField
                            id="max-price"
                            label="Maximum annual net price"
                            value={max_price}
                            onValue={lambda (value: str) { max_price = value; error = ""; remember(); }}
                            hint="What your family can pay per year after grants, in dollars. This is not a financial-aid offer."
                            placeholder="20000"
                            input_mode="decimal"
                        />
                        <Importance name="price-importance" value={price_importance} onValue={lambda (value: str) { price_importance = value; error = ""; remember(); }} />
                        <fieldset>
                            <legend className="group-legend">Graduation rate and typical earnings</legend>
                            <p className="hint">Typical earnings are a median for students who entered that college, not a salary offer.</p>
                            <Importance name="outcomes-importance" value={outcomes_importance} onValue={lambda (value: str) { outcomes_importance = value; error = ""; remember(); }} />
                        </fieldset>
                        <SelectField
                            id="income-bracket"
                            label="Household income"
                            value={income_bracket}
                            onValue={lambda (value: str) { income_bracket = value; error = ""; remember(); }}
                            hint="Used later to estimate net price. You can skip it."
                        >
                            <option value="">Prefer not to say</option>
                            {for band in INCOME {
                                <option key={band[0] as str} value={band[0] as str}>{band[1] as str}</option>
                            }}
                        </SelectField>
                        <SelectField
                            id="home-state"
                            label="Home state"
                            value={home_state}
                            onValue={lambda (value: str) { home_state = value; error = ""; remember(); }}
                            hint="Needed for in-state tuition and public-school admission rates."
                        >
                            <option value="">Select your state</option>
                            {for state in STATES {
                                <option key={state} value={state}>{state}</option>
                            }}
                        </SelectField>
                        <TextField
                            id="home-zip"
                            label="Home ZIP code"
                            value={home_zip}
                            onValue={lambda (value: str) { home_zip = value; error = ""; remember(); }}
                            hint="Used to measure distance from each college. 5 digits is enough."
                            placeholder="48104"
                            input_mode="numeric"
                        />
                        <SelectField
                            id="first-gen"
                            label="First-generation college student"
                            value={first_gen}
                            onValue={lambda (value: str) { first_gen = value; error = ""; remember(); }}
                            hint="Optional. Neither parent finished a four-year degree. Used to note colleges where more students are the first in their family to go."
                        >
                            <option value="">Prefer not to say</option>
                            <option value="yes">Yes</option>
                            <option value="no">No</option>
                        </SelectField>
                    </div>
                }}
                {if step == "5" {
                    <div className="stack">
                        <div className="review-block">
                            <div className="review-head">
                                <h3>Academics</h3>
                                <button type="button" className="edit-btn" onClick={lambda { go_to("0"); }}>Edit</button>
                            </div>
                            <dl className="review">
                                {review_item("Unweighted GPA", show(gpa_unweighted) + " / " + gpa_scale)}
                                {review_item("Weighted GPA", show(gpa_weighted))}
                                {review_item("Class percentile", show(class_percentile))}
                                {review_item("Class rank", show(class_rank))}
                                {review_item("Class size", show(class_size))}
                                {review_item("Course rigor", rigor_summary())}
                                {review_item("Graduation year", show(grad_year))}
                            </dl>
                        </div>
                        <div className="review-block">
                            <div className="review-head">
                                <h3>Tests</h3>
                                <button type="button" className="edit-btn" onClick={lambda { go_to("1"); }}>Edit</button>
                            </div>
                            <dl className="review">
                                {review_item("Plan", test_summary())}
                                {test_plan == "sat" and review_item("SAT reading and writing", show(sat_reading))}
                                {test_plan == "sat" and review_item("SAT math", show(sat_math))}
                                {test_plan == "act" and review_item("ACT English", show(act_english))}
                                {test_plan == "act" and review_item("ACT math", show(act_math))}
                                {test_plan == "act" and review_item("ACT reading", show(act_reading))}
                                {test_plan == "act" and review_item("ACT science", show(act_science))}
                            </dl>
                        </div>
                        <div className="review-block">
                            <div className="review-head">
                                <h3>Major</h3>
                                <button type="button" className="edit-btn" onClick={lambda { go_to("2"); }}>Edit</button>
                            </div>
                            <dl className="review">
                                {review_item("Intended study", majors_summary())}
                            </dl>
                        </div>
                        <div className="review-block">
                            <div className="review-head">
                                <h3>Campus</h3>
                                <button type="button" className="edit-btn" onClick={lambda { go_to("3"); }}>Edit</button>
                            </div>
                            <dl className="review">
                                {review_item("Regions", region_summary() + " (" + importance_label(location_importance) + ")")}
                                {review_item("Setting", setting_summary() + " (" + importance_label(setting_importance) + ")")}
                                {review_item("Distance", show(distance) + " (" + importance_label(distance_importance) + ")")}
                                {review_item("Size", size_summary() + " (" + importance_label(size_importance) + ")")}
                                {review_item("Type", control_summary() + " (" + importance_label(control_importance) + ")")}
                                {review_item("Religious affiliation", religious_summary() + " (" + importance_label(religious_importance) + ")")}
                                {review_item("HBCU", ("Yes" if want_hbcu == "yes" else "No") + " (" + importance_label(hbcu_importance) + ")")}
                                {review_item("Women's colleges", ("Yes" if want_womens == "yes" else "No") + " (" + importance_label(womens_importance) + ")")}
                            </dl>
                        </div>
                        <div className="review-block">
                            <div className="review-head">
                                <h3>Cost and home</h3>
                                <button type="button" className="edit-btn" onClick={lambda { go_to("4"); }}>Edit</button>
                            </div>
                            <dl className="review">
                                {review_item("Maximum net price", show(max_price) + " (" + importance_label(price_importance) + ")")}
                                {review_item("Graduation and earnings", importance_label(outcomes_importance))}
                                {review_item("Household income", income_summary())}
                                {review_item("Home state", show(home_state))}
                                {review_item("Home ZIP", show(home_zip))}
                                {review_item("First-generation", first_gen_summary())}
                            </dl>
                        </div>
                        <button type="button" className="text-btn" onClick={reset_profile}>Clear this profile</button>
                    </div>
                }}
                <div className="nav">
                    {step != "0" and <button type="button" className="secondary" onClick={prev_step}>Back</button>}
                    {if step == "5" {
                        <button type="button" className="primary">Submit</button>
                    } else {
                        <button type="button" className="primary" onClick={next_step}>Continue</button>
                    }}
                </div>
            </section>
        </main>
    </div>
}
