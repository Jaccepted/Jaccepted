"""Saved and dismissed colleges, kept in this browser like the intake draft."""

def read_json(key: str) -> any {
    try {
        raw = localStorage.getItem(key);
        if raw {
            return JSON.parse(raw);
        }
    } except Exception {
        return None;
    }
    return None;
}

def write_json(key: str, value: any) -> None {
    try {
        localStorage.setItem(key, JSON.stringify(value));
    } except Exception {
        return;
    }
}

def:pub load_saved -> list[dict[str, any]] {
    items = read_json("jaccepted.saved");
    if items {
        return items;
    }
    return [];
}

def:pub store_saved(items: list[dict[str, any]]) -> None {
    write_json("jaccepted.saved", items);
}

def:pub load_dismissed -> list[str] {
    ids = read_json("jaccepted.dismissed");
    if ids {
        return ids;
    }
    return [];
}

def:pub store_dismissed(ids: list[str]) -> None {
    write_json("jaccepted.dismissed", ids);
}

"""A warning when the saved list is lopsided, or "" when it looks balanced."""
def:pub balance_warning(items: list[dict[str, any]]) -> str {
    if len(items) == 0 {
        return "";
    }
    reach = len([item for item in items if item["bucket"] == "reach"]);
    likely = len([item for item in items if item["bucket"] == "likely"]);
    target = len(items) - reach - likely;
    if likely == 0 {
        return "You have 0 likely schools. Add at least one or two you are confident about.";
    }
    if reach > target + likely {
        return "Your list is reach-heavy: " + str(reach) + " reach, " + str(target) + " target, " + str(likely) + " likely.";
    }
    return "";
}
