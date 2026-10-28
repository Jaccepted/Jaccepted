test "requests are allowed up to the daily limit, then refused" {
    record = usage();
    record.day = today();
    record.calls = 0;
    for count in range(AI_DAILY_LIMIT) {
        assert use_ai_request();
    }
    assert not use_ai_request();
    assert record.calls == AI_DAILY_LIMIT;
    record.calls = 0;
}

test "the count resets on a new day" {
    record = usage();
    record.day = "2000-01-01";
    record.calls = AI_DAILY_LIMIT;
    assert use_ai_request();
    assert record.day == today();
    assert record.calls == 1;
    record.calls = 0;
}

test "the limit message names the limit" {
    assert str(AI_DAILY_LIMIT) in LIMIT_MESSAGE;
}
