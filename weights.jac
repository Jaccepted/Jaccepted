"""Rules for the per-preference weights the advisor can adjust.

Kept in their own module with no server-only imports, so the browser (which
reads saved weights from the profile) and the server (which scores colleges)
use the same rules.
"""

# Preferences the advisor can re-weight. Multipliers stay in a small range so one
# tool call cannot wipe a preference out or let it drown the rest.
glob:pub WEIGHT_KEYS: list[str] = ["major", "location", "setting", "distance", "size", "type", "religion", "hbcu", "womens", "price", "outcomes"];
glob:pub MIN_WEIGHT: float = 0.25;
glob:pub MAX_WEIGHT: float = 3.0;
glob:pub MAX_WEIGHT_CHANGES: int = 3;

"""Known preferences only, each clamped to MIN_WEIGHT..MAX_WEIGHT and rounded to 2 places.
Values of 1 (no change) and anything that isn't a finite number are dropped."""
def:pub sanitize_weights(raw: dict[str, any] | None) -> dict[str, float] {
    kept: dict[str, float] = {};
    if raw is None {
        return kept;
    }
    for key in WEIGHT_KEYS {
        if key not in raw {
            continue;
        }
        value = 0.0;
        try {
            value = float(raw[key]);
        } except Exception {
            continue;
        }
        # NaN is the only value not equal to itself; huge values stand in for infinity.
        if value != value or abs(value) > 1000000.0 or abs(value - 1.0) < 0.001 {
            continue;
        }
        clamped = max(MIN_WEIGHT, min(MAX_WEIGHT, value));
        kept[key] = float(int(clamped * 100.0 + 0.5)) / 100.0;
    }
    return kept;
}
