"""Saved and dismissed colleges, kept in this browser and the account."""

import from "@jac/runtime" { jacIsLoggedIn }
import from .accounts { load_dismissed_ids, load_list, save_dismissed, save_list }

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

async def:pub refresh_saved -> list[dict[str, any]] {
    if jacIsLoggedIn() {
        remote: dict[str, any] | None = None;
        try {
            remote = await load_list();
        } except Exception {
            remote = None;
        }
        if remote and remote.get("data") {
            try {
                parsed = JSON.parse(remote["data"] as str);
                if parsed {
                    write_json("jaccepted.saved", parsed);
                    return parsed as list[dict[str, any]];
                }
            } except Exception {
            }
        }
    }
    return load_saved();
}

def:pub store_saved(items: list[dict[str, any]]) -> None {
    write_json("jaccepted.saved", items);
    sync_saved(items);
}

async def sync_saved(items: list[dict[str, any]]) -> None {
    if not jacIsLoggedIn() {
        return;
    }
    try {
        await save_list(JSON.stringify(items));
    } except Exception {
        return;
    }
}

def:pub load_dismissed -> list[str] {
    ids = read_json("jaccepted.dismissed");
    if ids {
        return ids;
    }
    return [];
}

async def:pub refresh_dismissed -> list[str] {
    if jacIsLoggedIn() {
        remote: dict[str, any] | None = None;
        try {
            remote = await load_dismissed_ids();
        } except Exception {
            remote = None;
        }
        if remote and remote.get("data") {
            try {
                parsed = JSON.parse(remote["data"] as str);
                if parsed {
                    write_json("jaccepted.dismissed", parsed);
                    return parsed as list[str];
                }
            } except Exception {
            }
        }
    }
    return load_dismissed();
}

def:pub store_dismissed(ids: list[str]) -> None {
    write_json("jaccepted.dismissed", ids);
    sync_dismissed(ids);
}

async def sync_dismissed(ids: list[str]) -> None {
    if not jacIsLoggedIn() {
        return;
    }
    try {
        await save_dismissed(JSON.stringify(ids));
    } except Exception {
        return;
    }
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
