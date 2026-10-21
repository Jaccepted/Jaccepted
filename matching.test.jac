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
