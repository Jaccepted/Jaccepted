"""Per-user profile and list storage.

Authenticated callers get their own graph root, so each account only sees
its own intake draft and saved colleges.
"""

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

"""Save the intake form JSON for the signed-in user."""
def:priv save_intake(data: str) -> dict[str, any] {
    record = vault();
    record.intake_json = data;
    return {"success": True};
}

"""Load the intake form JSON, or an empty string when none is saved."""
def:priv load_intake -> dict[str, any] {
    record = vault();
    return {"success": True, "data": record.intake_json};
}

"""Save the My List JSON for the signed-in user."""
def:priv save_list(data: str) -> dict[str, any] {
    record = vault();
    record.saved_json = data;
    return {"success": True};
}

"""Load the My List JSON."""
def:priv load_list -> dict[str, any] {
    record = vault();
    return {"success": True, "data": record.saved_json};
}

"""Save the dismissed college ids JSON."""
def:priv save_dismissed(data: str) -> dict[str, any] {
    record = vault();
    record.dismissed_json = data;
    return {"success": True};
}

"""Load the dismissed college ids JSON."""
def:priv load_dismissed_ids -> dict[str, any] {
    record = vault();
    return {"success": True, "data": record.dismissed_json};
}
