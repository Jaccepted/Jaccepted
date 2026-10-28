test "saves within the limit are stored" {
    assert save_list("[]")["success"];
    assert load_list()["data"] == "[]";
}

test "oversized saves are refused and keep the previous data" {
    assert save_intake("{\"gpa_unweighted\": \"3.5\"}")["success"];
    result = save_intake("x" * (MAX_SAVE_CHARS + 1));
    assert not result["success"];
    assert result["error"] == TOO_LARGE;
    assert load_intake()["data"] == "{\"gpa_unweighted\": \"3.5\"}";
}

test "every save endpoint checks the limit" {
    big = "x" * (MAX_SAVE_CHARS + 1);
    assert not save_intake(big)["success"];
    assert not save_list(big)["success"];
    assert not save_dismissed(big)["success"];
}
