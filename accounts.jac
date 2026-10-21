"""Per-user profile and list storage.

Authenticated callers get their own graph root, so each account only sees
its own intake draft and saved colleges. The browser still keeps a local
fallback so the app remains usable while signed out.
"""
import from "@jac/runtime" { jacIsLoggedIn }

node StudentVault {
    has intake_json: str = "",
        saved_json: str = "[]",
        dismissed_json: str = "[]";
}

def vault -> StudentVault {
    found = [root -->][?:StudentVault];
    if found {
        return found[0];
    }
    return root ++> StudentVault();
}

def:priv local_value(key: str, fallback: str = "") -> str {
    try {
        raw = localStorage.getItem(key);
        if raw is not None {
            return raw as str;
        }
    } except Exception {
        return fallback;
    }
    return fallback;
}

"""Save the intake form JSON for the signed-in user and keep a local fallback."""
def:pub save_intake(data: str) -> dict[str, any] {
    try {
        localStorage.setItem("jaccepted.intake", data);
    } except Exception {
    }
    if jacIsLoggedIn() {
        record = vault();
        record.intake_json = data;
    }
    return {"success": True};
}

"""Load the intake form JSON, preferring the signed-in vault but falling back to local storage."""
def:pub load_intake -> dict[str, any] {
    if jacIsLoggedIn() {
        record = vault();
        if record.intake_json != "" {
            return {"success": True, "data": record.intake_json};
        }
    }
    raw = local_value("jaccepted.intake", "");
    return {"success": True, "data": raw};
}

"""Save the My List JSON for the signed-in user and keep a local fallback."""
def:pub save_list(data: str) -> dict[str, any] {
    try {
        localStorage.setItem("jaccepted.saved", data);
    } except Exception {
    }
    if jacIsLoggedIn() {
        record = vault();
        record.saved_json = data;
    }
    return {"success": True};
}

"""Load the My List JSON, preferring the signed-in vault but falling back to local storage."""
def:pub load_list -> dict[str, any] {
    if jacIsLoggedIn() {
        record = vault();
        if record.saved_json != "" and record.saved_json != "[]" {
            return {"success": True, "data": record.saved_json};
        }
    }
    raw = local_value("jaccepted.saved", "[]");
    return {"success": True, "data": raw};
}

"""Save the dismissed college ids JSON for the signed-in user and keep a local fallback."""
def:pub save_dismissed(data: str) -> dict[str, any] {
    try {
        localStorage.setItem("jaccepted.dismissed", data);
    } except Exception {
    }
    if jacIsLoggedIn() {
        record = vault();
        record.dismissed_json = data;
    }
    return {"success": True};
}

"""Load the dismissed college ids JSON, preferring the signed-in vault but falling back to local storage."""
def:pub load_dismissed_ids -> dict[str, any] {
    if jacIsLoggedIn() {
        record = vault();
        if record.dismissed_json != "" and record.dismissed_json != "[]" {
            return {"success": True, "data": record.dismissed_json};
        }
    }
    raw = local_value("jaccepted.dismissed", "[]");
    return {"success": True, "data": raw};
}
