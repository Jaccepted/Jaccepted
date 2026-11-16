test "sanitize_weights keeps known preferences, clamped and rounded" {
    assert sanitize_weights(None) == {};
    assert sanitize_weights({"price": 2.0, "unknown": 2.0}) == {"price": 2.0};
    assert sanitize_weights({"price": 99}) == {"price": MAX_WEIGHT};
    assert sanitize_weights({"price": 0}) == {"price": MIN_WEIGHT};
    assert sanitize_weights({"price": "1.5"}) == {"price": 1.5};
    assert sanitize_weights({"price": 1.333}) == {"price": 1.33};
}

test "sanitize_weights drops no-change and non-numbers" {
    assert sanitize_weights({"price": 1.0}) == {};
    assert sanitize_weights({"price": "lots"}) == {};
    assert sanitize_weights({"price": float("nan")}) == {};
    assert sanitize_weights({"price": float("inf")}) == {};
}
