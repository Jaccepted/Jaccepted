import from jaclang.byllm.lib { MockLLM, MockToolCall }

# Each test that reaches the model first sets advisor_llm to a MockLLM: no API key, no cost.


def cs_profile -> Profile {
    return Profile(
        gpa_unweighted="3.9",
        test_plan="sat",
        sat_total="1450",
        major1="Computer Science",
        income_bracket="48001-75000",
        home_zip="48104"
    );
}

def open_session(profile: Profile) -> Advisor {
    request_id = "test-" + profile.sat_total;
    SESSIONS[request_id] = passing_colleges(profile);
    return Advisor(request_id=request_id);
}

test "find_colleges filters by bucket, region, type and price" {
    advisor = open_session(cs_profile());
    cards = advisor.find_colleges("likely", "Midwest", "", "public", 20000, "fit", 10);
    assert 0 < len(cards) <= 10;
    for item in cards {
        assert item.bucket == "likely";
        assert item.region == "Midwest";
        assert item.kind == "public";
    }
}

test "find_colleges caps the limit and sorts by price" {
    advisor = open_session(cs_profile());
    cards = advisor.find_colleges("", "", "", "", 0, "price", 500);
    assert len(cards) == TOOL_LIMIT;
    prices = [int(item.net_price.replace("$", "").replace(",", "").replace("/yr", "")) for item in cards if item.net_price != "not published"];
    assert prices == sorted(prices);
}

test "college_facts refuses colleges outside the student's matches" {
    advisor = open_session(cs_profile());
    assert "Not in this student's matches" in advisor.college_facts("000000");
    assert "University of Michigan" in advisor.college_facts("170976");
}

test "check_balance counts buckets and flags unknown ids" {
    advisor = open_session(cs_profile());
    text = advisor.check_balance(["170976", "000000"]);
    assert "1 target" in text;
    assert "000000" in text;
}

test "invented, duplicate and extra picks are dropped" {
    matches = passing_colleges(cs_profile());
    real = [item.unitid for item in matches[:20]];
    plan = AdvisorPlan(
        message="Here is your list.",
        picks=[AdvisorPick(unitid=real[0], why="a"), AdvisorPick(unitid="000000", why="made up"), AdvisorPick(unitid=real[0], why="again")]
            + [AdvisorPick(unitid=unitid, why="more") for unitid in real[1:]]
    );
    result = grounded(plan, matches);
    ids = [pick.unitid for pick in result.picks];
    assert "000000" not in ids;
    assert len(ids) == len(set(ids)) == MAX_PICKS;
    assert result.reach + result.target + result.likely == MAX_PICKS;
}

test "the agent calls a tool, then answers with grounded picks" {
    llm = MockLLM(outputs=[
        MockToolCall(tool="find_colleges", args={"bucket": "", "region": "Midwest", "state": "", "college_type": "", "max_net_price": 0, "sort_by": "fit", "limit": 5}),
        MockToolCall(tool="finish_tool", args={"final_output": {
            "message": "A Midwest list.",
            "picks": [{"unitid": "170976", "why": "Strong CS, close to home."}, {"unitid": "000000", "why": "Invented."}],
            "follow_ups": ["Add more likely schools", "Only public colleges"]
        }})
    ]);
    advisor_llm = llm;
    result = ask_advisor("Midwest schools for computer science", cs_profile());
    assert result.ok;
    assert [pick.unitid for pick in result.picks] == ["170976"];
    assert result.picks[0].name.startswith("University of Michigan");
    assert "Midwest schools" in str(llm.sent("messages"));
    assert "find_colleges" in str(llm.sent("tools"));
    assert "48104" not in str(llm.sent("messages")), "the student's ZIP must not reach the model";
    assert len(result.steps) == 1 and result.steps[0].startswith("Searched Midwest colleges");
    assert result.follow_ups == ["Add more likely schools", "Only public colleges", "Make the list cheaper"];
}

test "a refinement starts from the current list and drops ids that are not matches" {
    llm = MockLLM(outputs=[
        MockToolCall(tool="finish_tool", args={"final_output": {"message": "Kept it.", "picks": [{"unitid": "170976", "why": "Kept."}]}})
    ]);
    advisor_llm = llm;
    result = ask_advisor("Keep my list", cs_profile(), ["170976", "000000"]);
    assert result.ok;
    assert result.steps == ["Started from your current list of 1 college."];
    assert "170976" in str(llm.sent("messages"));
    assert "000000" not in str(llm.sent("messages"));
}

test "an empty request is refused without calling the model" {
    result = ask_advisor("   ", cs_profile());
    assert not result.ok;
}

test "a model failure returns a friendly message" {
    advisor_llm = MockLLM(outputs=[]);
    result = ask_advisor("Anything", cs_profile());
    assert not result.ok;
    assert "unavailable" in result.message;
}

test "reasons lose a leading bucket label" {
    assert clean_why("Reach: admits 5% of applicants.") == "admits 5% of applicants.";
    assert clean_why("Likely. Close to home.") == "Close to home.";
    assert clean_why("Strong CS program.") == "Strong CS program.";
}

test "follow-ups drop questions and fill with defaults" {
    assert clean_follow_ups(["Should I add schools outside the Midwest?"]) == DEFAULT_FOLLOW_UPS;
    assert clean_follow_ups(["Add a school in Ohio", "", "a" * 80]) == ["Add a school in Ohio", "Add more likely schools", "Make the list cheaper"];
}
