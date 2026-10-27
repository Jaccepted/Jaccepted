"""Per-user profile and list storage.

Signed-in callers get their own graph root, so each account only sees its own
intake draft and saved colleges. These are server endpoints: the browser's
local-storage fallback for signed-out visitors lives in the client modules
(frontend.jac and list_store.jac), which only call these when logged in.
"""

# Upper bound on each saved JSON string. A full profile is a few KB and a long
# tracker list with notes stays well under 100 KB, so this only stops abuse.
glob MAX_SAVE_CHARS: int = 500000;
glob TOO_LARGE: str = "That is too much data to save. Remove some notes or colleges and try again.";

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
def:protect save_intake(data: str) -> dict[str, any] {
    if len(data) > MAX_SAVE_CHARS {
        return {"success": False, "error": TOO_LARGE};
    }
    record = vault();
    record.intake_json = data;
    return {"success": True};
}

"""Load the intake form JSON, or an empty string when none is saved."""
def:protect load_intake -> dict[str, any] {
    record = vault();
    return {"success": True, "data": record.intake_json};
}

"""Save the My List JSON for the signed-in user."""
def:protect save_list(data: str) -> dict[str, any] {
    if len(data) > MAX_SAVE_CHARS {
        return {"success": False, "error": TOO_LARGE};
    }
    record = vault();
    record.saved_json = data;
    return {"success": True};
}

"""Load the My List JSON for the signed-in user."""
def:protect load_list -> dict[str, any] {
    record = vault();
    return {"success": True, "data": record.saved_json};
}

"""Save the dismissed college ids JSON for the signed-in user."""
def:protect save_dismissed(data: str) -> dict[str, any] {
    if len(data) > MAX_SAVE_CHARS {
        return {"success": False, "error": TOO_LARGE};
    }
    record = vault();
    record.dismissed_json = data;
    return {"success": True};
}

"""Load the dismissed college ids JSON for the signed-in user."""
def:protect load_dismissed_ids -> dict[str, any] {
    record = vault();
    return {"success": True, "data": record.dismissed_json};
}
