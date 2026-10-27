import from jaclang.byllm.lib { MockLLM }

# Each test that reaches the model first sets essay_llm to a MockLLM: no API key, no cost.

test "drafted essay text is dropped, advice is kept" {
    ideas = EssayIdeas(angles=[
        EssayAngle(title="Robotics", essay_type="Why this major", idea="You could write about debugging the robot arm and why CS draws you in."),
        EssayAngle(title="Draft", essay_type="Why this major", idea="I have always loved computers since I was young."),
        EssayAngle(title="Too long", essay_type="Why this major", idea=" ".join(["word"] * 60))
    ]);
    kept = safe_ideas(ideas);
    assert [item.title for item in kept] == ["Robotics"];
}

test "unknown essay types fall back to topic of your choice" {
    kept = safe_ideas(EssayIdeas(angles=[EssayAngle(title="X", essay_type="Made-up prompt 9", idea="You could write about the garden you started.")]));
    assert kept[0].essay_type == "Common App: topic of your choice";
}

test "at most four ideas" {
    many = EssayIdeas(angles=[EssayAngle(title="T" + str(n), essay_type="Why this college", idea="You could write about your project.") for n in range(7)]);
    assert len(safe_ideas(many)) == MAX_ANGLES;
}

test "the college brief only lists majors the college offers" {
    brief = brief_for("170976", ["Computer Science", "Nursing", "Not A Major"]);
    assert brief is not None and brief.name.startswith("University of Michigan");
    assert "Computer Science" in brief.programs;
    assert "Not A Major" not in brief.programs;
}

test "essay ideas run through the model with the rules and the student's notes" {
    llm = MockLLM(outputs=[
        EssayIdeas(
            angles=[
                EssayAngle(title="The robot arm", essay_type="Why this major", idea="You could write about rebuilding the robot arm and how it led you to CS.", questions=["What broke?"]),
                EssayAngle(title="Copied", essay_type="Why this major", idea="My robot taught me patience.")
            ],
            note="I only suggest ideas; the writing is yours."
        )
    ]);
    essay_llm = llm;
    result = essay_ideas("170976", ["Computer Science"], "Robotics club captain. Rebuilt our robot arm after it broke before regionals.");
    assert result.ok;
    assert [item.title for item in result.ideas] == ["The robot arm"];
    sent = str(llm.sent("messages"));
    assert "Never write essay text" in sent;
    assert "Rebuilt our robot arm" in sent;
}

test "a model with no answer gives a friendly message" {
    essay_llm = MockLLM(outputs=[]);
    result = essay_ideas("170976", ["Computer Science"], "notes");
    assert not result.ok;
}

test "an unknown college is refused without calling the model" {
    result = essay_ideas("000000", ["Computer Science"], "notes");
    assert not result.ok;
}
