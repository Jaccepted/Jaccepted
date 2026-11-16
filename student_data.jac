"""Per-student data kept in this browser, and when to forget it.

The profile, saved list, chat and essay notes are cached in localStorage so the
app feels instant. That cache belongs to one account: when a different account
signs in on the same browser, the old student's data must not carry over.
The light/dark choice is not student data and is kept.
"""

glob STUDENT_KEYS: list[str] = ["jaccepted.intake", "jaccepted.saved", "jaccepted.dismissed", "jaccepted.advisor", "jaccepted.essay_notes"];

# The account the cached data belongs to.
glob ACCOUNT_KEY: str = "jaccepted.account";

"""Remove this student's data from the browser."""
def:pub forget_student_data -> None {
    try {
        for key in STUDENT_KEYS {
            localStorage.removeItem(key);
        }
        localStorage.removeItem(ACCOUNT_KEY);
    } except Exception {
        return;
    }
}

"""Call after a successful sign in or sign up.

Clears the cached data unless it already belongs to this account, then records
the account. Data from an older version (no account recorded) is cleared too,
since we can't tell whose it is. The profile and saved list come back from the
account on the next page load.
"""
def:pub claim_browser_for(email: str) -> None {
    account = email.strip().lower();
    owner = "";
    try {
        stored = localStorage.getItem(ACCOUNT_KEY);
        if stored {
            owner = stored as str;
        }
    } except Exception {
        owner = "";
    }
    if owner != account {
        forget_student_data();
    }
    try {
        localStorage.setItem(ACCOUNT_KEY, account);
    } except Exception {
        return;
    }
}
