"""Validation for the profile intake form.

These checks cover the MVP fields: academics, test scores, majors are free
text, and the core campus and cost preferences. Activities are out of scope.
"""

def parse_num(raw: str) -> float | None {
    text = raw.strip();
    if not text {
        return None;
    }
    try {
        return float(text);
    } except Exception {
        return None;
    }
}

def range_error(
    label: str,
    raw: str,
    low: float,
    high: float,
    required: bool,
    bounds: str
) -> str {
    text = raw.strip();
    if not text {
        if required {
            return label + " is required.";
        }
        return "";
    }
    value = parse_num(text);
    if value is None {
        return label + " must be a number.";
    }
    if value < low or value > high {
        return label + " must be between " + bounds + ".";
    }
    return "";
}

def whole_error(
    label: str,
    raw: str,
    low: int,
    high: int,
    required: bool,
    bounds: str
) -> str {
    text = raw.strip();
    if not text {
        if required {
            return label + " is required.";
        }
        return "";
    }
    value = parse_num(text);
    if value is None or value != int(value) {
        return label + " must be a whole number.";
    }
    if value < low or value > high {
        return label + " must be between " + bounds + ".";
    }
    return "";
}

def rank_error(rank: str, size: str) -> str {
    rank_text = rank.strip();
    size_text = size.strip();
    if not rank_text and not size_text {
        return "";
    }
    if not rank_text or not size_text {
        return "Enter both class rank and class size, or leave both blank.";
    }
    rank_num = parse_num(rank_text);
    size_num = parse_num(size_text);
    if rank_num is None or size_num is None or rank_num != int(rank_num) or size_num != int(size_num) {
        return "Class rank and class size must be whole numbers.";
    }
    if rank_num < 1 or size_num < 1 or rank_num > size_num {
        return "Class rank must be between 1 and the class size.";
    }
    return "";
}

def scale_limit(scale: str) -> float {
    if scale == "100" {
        return 100.0;
    }
    if scale == "5.0" {
        return 5.0;
    }
    return 4.0;
}

def scale_bounds(scale: str) -> str {
    if scale == "100" {
        return "0 and 100";
    }
    if scale == "5.0" {
        return "0 and 5.0";
    }
    return "0 and 4.0";
}

def academics_error(
    gpa_unweighted: str,
    gpa_weighted: str,
    gpa_scale: str,
    class_percentile: str,
    class_rank: str,
    class_size: str,
    ap_count: str,
    ib_count: str,
    honors_count: str,
    dual_count: str,
    grad_year: str
) -> str {
    gpa_message = range_error(
        "Unweighted GPA",
        gpa_unweighted,
        0.0,
        scale_limit(gpa_scale),
        True,
        scale_bounds(gpa_scale)
    );
    if gpa_message {
        return gpa_message;
    }
    weighted_message = "";
    if gpa_weighted.strip() {
        weighted_message = range_error(
            "Weighted GPA",
            gpa_weighted,
            0.0,
            scale_limit(gpa_scale),
            False,
            scale_bounds(gpa_scale)
        );
    }
    if weighted_message {
        return weighted_message;
    }
    percentile_message = whole_error(
        "Class percentile",
        class_percentile,
        1,
        100,
        False,
        "1 and 100"
    );
    if percentile_message {
        return percentile_message;
    }
    rank_message = rank_error(class_rank, class_size);
    if rank_message {
        return rank_message;
    }
    ap_message = whole_error("AP courses", ap_count, 0, 40, False, "0 and 40");
    if ap_message {
        return ap_message;
    }
    ib_message = whole_error("IB courses", ib_count, 0, 40, False, "0 and 40");
    if ib_message {
        return ib_message;
    }
    honors_message = whole_error("Honors courses", honors_count, 0, 40, False, "0 and 40");
    if honors_message {
        return honors_message;
    }
    dual_message = whole_error(
        "Dual-enrollment courses",
        dual_count,
        0,
        40,
        False,
        "0 and 40"
    );
    if dual_message {
        return dual_message;
    }
    if not grad_year.strip() {
        return "Graduation year is required.";
    }
    return "";
}

def tests_error(
    test_plan: str,
    sat_total: str,
    sat_reading: str,
    sat_math: str,
    act_composite: str,
    act_english: str,
    act_math: str,
    act_reading: str,
    act_science: str
) -> str {
    if test_plan == "sat" {
        total_message = whole_error("SAT total", sat_total, 400, 1600, True, "400 and 1600");
        if total_message {
            return total_message;
        }
        reading_message = whole_error(
            "SAT Evidence-Based Reading and Writing",
            sat_reading,
            200,
            800,
            False,
            "200 and 800"
        );
        if reading_message {
            return reading_message;
        }
        math_message = whole_error("SAT Math", sat_math, 200, 800, False, "200 and 800");
        if math_message {
            return math_message;
        }
        if sat_reading.strip() and sat_math.strip() {
            reading = parse_num(sat_reading);
            math_score = parse_num(sat_math);
            total = parse_num(sat_total);
            if reading is not None and math_score is not None and total is not None {
                if abs(reading + math_score - total) > 0.01 {
                    return "SAT Evidence-Based Reading and Writing plus Math should equal your total.";
                }
            }
        }
        return "";
    }
    if test_plan == "act" {
        composite_message = whole_error("ACT composite", act_composite, 1, 36, True, "1 and 36");
        if composite_message {
            return composite_message;
        }
        english_message = whole_error("ACT English", act_english, 1, 36, False, "1 and 36");
        if english_message {
            return english_message;
        }
        act_math_message = whole_error("ACT Math", act_math, 1, 36, False, "1 and 36");
        if act_math_message {
            return act_math_message;
        }
        act_reading_message = whole_error("ACT Reading", act_reading, 1, 36, False, "1 and 36");
        if act_reading_message {
            return act_reading_message;
        }
        science_message = whole_error("ACT Science", act_science, 1, 36, False, "1 and 36");
        if science_message {
            return science_message;
        }
    }
    return "";
}

def campus_error(
    distance: str,
    size_small: str,
    size_medium: str,
    size_large: str,
    want_public: str,
    want_private: str
) -> str {
    distance_message = range_error(
        "Maximum distance",
        distance,
        1.0,
        5000.0,
        False,
        "1 and 5000"
    );
    if distance_message {
        return distance_message;
    }
    if size_small != "yes" and size_medium != "yes" and size_large != "yes" {
        return "Select at least one campus size, or leave all three selected if size does not matter.";
    }
    if want_public != "yes" and want_private != "yes" {
        return "Select public, private, or both.";
    }
    return "";
}

def zip_error(raw: str) -> str {
    text = raw.strip();
    if not text {
        return "";
    }
    compact = text.replace("-", "").replace(" ", "");
    value = parse_num(compact);
    if value is None or value != int(value) or (len(compact) != 5 and len(compact) != 9) {
        return "Home ZIP must be 5 digits, or 5 digits plus 4.";
    }
    return "";
}

def cost_error(max_price: str, home_zip: str) -> str {
    price_message = range_error(
        "Maximum net price",
        max_price,
        0.0,
        200000.0,
        False,
        "0 and 200000"
    );
    if price_message {
        return price_message;
    }
    return zip_error(home_zip);
}

def show(value: str) -> str {
    text = value.strip();
    if text {
        return text;
    }
    return "Not provided";
}

def importance_label(value: str) -> str {
    if value == "must" {
        return "Must have";
    }
    if value == "nice" {
        return "Nice to have";
    }
    return "Don't care";
}

def join_csv(items: list[str]) -> str {
    text = "";
    for item in items {
        if text {
            text = text + "," + item;
        } else {
            text = item;
        }
    }
    return text;
}

def join_labels(items: list[str], empty: str) -> str {
    text = "";
    for item in items {
        if text {
            text = text + ", " + item;
        } else {
            text = item;
        }
    }
    if text {
        return text;
    }
    return empty;
}
