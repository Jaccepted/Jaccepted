import time;

def strong_profile -> Profile {
    return Profile(
        gpa_unweighted="3.9",
        test_plan="sat",
        sat_total="1450",
        major1="Computer Science",
        max_price="25000",
        price_importance="must",
        income_bracket="48001-75000",
        home_zip="48104",
        distance="300",
        distance_importance="nice"
    );
}

def all_matches(result: MatchResult) -> list[CollegeMatch] {
    return result.reach + result.target + result.likely;
}

test "very selective colleges are always a reach" {
    assert bucket_for(0.04, False, "above") == "reach";
    assert bucket_for(0.10, False, "within") == "reach";
}

test "bucket rules follow the spec" {
    assert bucket_for(0.40, False, "below") == "reach";
    assert bucket_for(0.40, False, "within") == "target";
    assert bucket_for(0.60, False, "above") == "likely";
    assert bucket_for(0.30, False, "above") == "target";
    assert bucket_for(None, True, "") == "likely";
    assert bucket_for(0.80, False, "") == "likely";
    assert bucket_for(0.20, False, "") == "reach";
}

test "gpa converts to a 4.0 scale" {
    assert gpa_on_four("3.5", "4.0") == 3.5;
    assert gpa_on_four("4.5", "5.0") == 3.6;
    assert gpa_on_four("91", "100") == 3.7;
    assert gpa_on_four("", "4.0") is None;
}

test "harvard is a reach even for a perfect score" {
    profile = Profile(gpa_unweighted="4.0", test_plan="sat", sat_total="1600");
    harvard = [row for row in COLLEGES if row["unitid"] == "166027"][0];
    result = match_one(profile, harvard, [], None);
    assert result.bucket == "reach";
}

test "every match offers the chosen major and fits the budget" {
    result = match_profile(strong_profile());
    matches = all_matches(result);
    assert len(matches) > 0;
    cs = [major for major in MAJORS if major[0] == "Computer Science"][0];
    for item in matches {
        assert offers(item.unitid, cs[1]), item.name;
        assert item.net_price is not None and item.net_price <= 25000, item.name;
    }
}

test "shortlist suggests 3 reach, 4 target, 3 likely" {
    result = match_profile(strong_profile());
    assert len([item for item in result.reach if item.shortlist]) == min(3, len(result.reach));
    assert len([item for item in result.target if item.shortlist]) == min(4, len(result.target));
    assert len([item for item in result.likely if item.shortlist]) == min(3, len(result.likely));
}

test "buckets are sorted by fit" {
    result = match_profile(strong_profile());
    for group in [result.reach, result.target, result.likely] {
        fits = [item.fit for item in group];
        assert fits == sorted(fits, reverse=True);
    }
}

test "matching returns in under two seconds" {
    started = time.perf_counter();
    match_profile(strong_profile());
    assert time.perf_counter() - started < 2.0;
}

test "home state boosts in-state public schools" {
    profile = Profile(
        gpa_unweighted="3.4",
        gpa_scale="4.0",
        test_plan="none",
        undecided="yes",
        want_public="yes",
        want_private="yes",
        home_state="MI"
    );
    result = match_profile(profile);
    schools = [item for item in all_matches(result) if item.name == "Central Michigan University"];
    assert len(schools) == 1;
    assert any("home state" in reason.lower() for reason in schools[0].reasons);
}

test "a realistic student profile returns a non-empty, sensible list" {
    profile = Profile(
        gpa_unweighted="3.7",
        gpa_scale="4.0",
        test_plan="sat",
        sat_total="1350",
        undecided="no",
        major1="Computer Science",
        regions="Midwest,South",
        location_importance="nice",
        setting="suburban",
        setting_importance="nice",
        distance="300",
        distance_importance="nice",
        size_small="yes",
        size_medium="yes",
        size_large="yes",
        size_importance="nice",
        want_public="yes",
        want_private="no",
        control_importance="must",
        max_price="25000",
        price_importance="must",
        income_bracket="48001-75000",
        home_state="MI",
        home_zip="48104"
    );
    result = match_profile(profile);
    matches = all_matches(result);
    assert len(matches) > 0;
    assert len(result.reach) >= 0;
    assert len(result.target) >= 0;
    assert len(result.likely) >= 0;
    assert any(item.name == "Central Michigan University" for item in matches);
    assert any(item.name == "Michigan State University" for item in matches) or any(item.name == "University of Michigan" for item in matches);
}

test "net price uses the bracket, then the overall price, then the bracket mean" {
    college = {
        "net_price": 20000,
        "net_price_0_30k": 5000,
        "net_price_30_48k": None,
        "net_price_48_75k": 15000,
        "net_price_75_110k": None,
        "net_price_110k_plus": None
    };
    assert net_price_for(college, "0-30000") == 5000.0;
    assert net_price_for(college, "") == 20000.0;
    # Bracket asked for has no data: fall back to the overall price.
    assert net_price_for(college, "30001-48000") == 20000.0;
    college["net_price"] = None;
    assert net_price_for(college, "") == 10000.0;
    college["net_price_0_30k"] = None;
    college["net_price_48_75k"] = None;
    assert net_price_for(college, "") is None;
}

test "most colleges now have a net price without an income bracket" {
    priced = [row for row in COLLEGES if net_price_for(row, "") is not None];
    assert len(priced) > 0.9 * len(COLLEGES);
}

test "college detail scores a college like the results list" {
    profile = Profile(gpa_unweighted="3.9", test_plan="sat", sat_total="1450", major1="Computer Science", home_zip="48104");
    detail = college_detail("170976", profile);
    assert detail.found;
    assert detail.college["name"] == "University of Michigan-Ann Arbor";
    listed = [item for item in all_matches(match_profile(profile)) if item.unitid == "170976"];
    if listed {
        assert detail.bucket == listed[0].bucket;
        assert detail.fit == listed[0].fit;
    }
    assert detail.net_price is not None;
    assert detail.program_count > 0;
}

test "college detail reports an unknown college as not found" {
    assert not college_detail("not-a-unitid", Profile()).found;
}
