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
    assert any(item.name == "Michigan State University" for item in matches) or any(item.name == "University of Michigan-Ann Arbor" for item in matches);
}

test "computer science also matches colleges that file it as general computer and information sciences" {
    michigan = [row for row in COLLEGES if row["unitid"] == "170976"][0];
    assert offers("170976", [str(prefix) for prefix in chosen_majors(Profile(major1="Computer Science"))[0][1]]);
    assert must_have_failure(Profile(major1="Computer Science"), michigan, chosen_majors(Profile(major1="Computer Science")), None) == "";
}

def fake(unitid: str, name: str, fit: int, admit: float | None, price: int | None, miles: int | None) -> CollegeMatch {
    return CollegeMatch(
        unitid=unitid, name=name, city="Town", state="MI", bucket="target",
        fit=fit, admit_rate=admit, net_price=price, miles=miles
    );
}

test "sorting by fit is the default, best first" {
    items = [fake("a", "A", 60, 0.5, 1, 1), fake("b", "B", 90, 0.5, 1, 1), fake("c", "C", 75, 0.5, 1, 1)];
    assert [item.unitid for item in ranked(items, "target", "fit")] == ["b", "c", "a"];
}

test "sorting by admit rate, price, and distance goes low to high with missing values last" {
    items = [
        fake("a", "A", 60, 0.50, 30000, 200),
        fake("b", "B", 90, None, None, None),
        fake("c", "C", 75, 0.20, 10000, 50)
    ];
    assert [item.unitid for item in ranked(items, "target", "admit")] == ["c", "a", "b"];
    assert [item.unitid for item in ranked(items, "target", "price")] == ["c", "a", "b"];
    assert [item.unitid for item in ranked(items, "target", "distance")] == ["c", "a", "b"];
}

test "sorting by name is alphabetical" {
    items = [fake("z", "Zeta", 90, 0.5, 1, 1), fake("a", "Alpha", 60, 0.5, 1, 1)];
    assert [item.unitid for item in ranked(items, "target", "name")] == ["a", "z"];
}

test "the shortlist is the best fits no matter how the list is sorted" {
    items = [fake(str(n), "College " + str(n), 50 + n, 0.9 - n * 0.01, None, None) for n in range(8)];
    by_price = ranked(items, "target", "name");
    flagged = sorted([item.unitid for item in by_price if item.shortlist]);
    # SHORTLIST gives target 4 slots: the four highest fits are ids 7, 6, 5, 4.
    assert flagged == ["4", "5", "6", "7"];
}

test "an unknown sort falls back to best fit" {
    items = [fake("a", "A", 60, 0.5, 1, 1), fake("b", "B", 90, 0.5, 1, 1)];
    assert [item.unitid for item in ranked(items, "target", "nonsense")] == ["b", "a"];
}

test "a search matches name, city, or state abbreviation" {
    item = CollegeMatch(unitid="1", name="University of Michigan-Ann Arbor", city="Ann Arbor", state="MI", bucket="reach", fit=50);
    assert matches_query(item, "");
    assert matches_query(item, "  michigan ");
    assert matches_query(item, "ann arbor");
    assert matches_query(item, "mi");
    assert not matches_query(item, "ohio");
    # A state needs its full abbreviation, so "m" does not match Michigan by state alone.
    plain = CollegeMatch(unitid="2", name="Alpha", city="Town", state="MI", bucket="reach", fit=50);
    assert matches_query(plain, "MI");
    assert not matches_query(plain, "m");
}

test "a state code searches by state only, not names that contain those letters" {
    hamilton = CollegeMatch(unitid="3", name="Hamilton College", city="Clinton", state="NY", bucket="reach", fit=50);
    assert not matches_query(hamilton, "MI");
    assert matches_query(hamilton, "NY");
    assert matches_query(hamilton, "hamil");
    # Longer searches are still name and city searches.
    assert matches_query(hamilton, "clint");
}

test "filtering by state narrows the real results and the counts" {
    everything = match_profile(strong_profile());
    in_state = match_profile(strong_profile(), "MI", "fit");
    assert in_state.reach_count + in_state.target_count + in_state.likely_count > 0;
    assert in_state.reach_count + in_state.target_count + in_state.likely_count < everything.reach_count + everything.target_count + everything.likely_count;
    for item in all_matches(in_state) {
        assert item.state == "MI";
    }
}

test "a search with no matches returns empty buckets, not an error" {
    result = match_profile(strong_profile(), "zzzz-no-such-college", "fit");
    assert all_matches(result) == [];
    assert result.reach_count == 0 and result.target_count == 0 and result.likely_count == 0;
}

test "sorting real results by price is ascending in every bucket" {
    result = match_profile(strong_profile(), "", "price");
    for bucket in [result.reach, result.target, result.likely] {
        prices = [item.net_price for item in bucket if item.net_price is not None];
        assert prices == sorted(prices);
    }
}

test "sorting by distance without a ZIP explains why" {
    result = match_profile(Profile(gpa_unweighted="3.5"), "", "distance");
    assert any("ZIP" in note for note in result.notes);
}
