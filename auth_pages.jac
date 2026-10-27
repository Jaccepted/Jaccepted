"""Sign in and create-account screens."""

import from "@jac/runtime" { Link, SignupResult, jacLogin, jacSignup, useNavigate }
import from .components.fields { TextField }
import from .components.logo { Logo }
import from .theme {
    BANNER,
    CARD,
    EYEBROW,
    HINT,
    LEDE,
    LINK,
    NAV,
    PAGE,
    PRIMARY,
    SECONDARY,
    SECTION_TITLE,
    STACK,
    TITLE
}

def valid_email(raw: str) -> bool {
    text = raw.strip();
    if len(text) < 5 {
        return False;
    }
    if "@" not in text {
        return False;
    }
    parts = text.split("@");
    if len(parts) != 2 {
        return False;
    }
    if not parts[0] or not parts[1] or "." not in parts[1] {
        return False;
    }
    return True;
}

def:pub LoginForm -> JsxElement {
    has email: str = "",
        password: str = "",
        error: str = "",
        busy: str = "no";

    navigate = useNavigate();

    async def submit -> None {
        if busy == "yes" {
            return;
        }
        if not valid_email(email) {
            error = "Enter a valid email address.";
            return;
        }
        if len(password) < 6 {
            error = "Password must be at least 6 characters.";
            return;
        }
        busy = "yes";
        error = "";
        ok: bool = False;
        try {
            # Pass an email identity explicitly - a bare string is treated as a username.
            ok = await jacLogin({"type": "email", "value": email.strip()}, password);
        } except Exception {
            busy = "no";
            error = "Sign in failed. Check that the app is running, then try again.";
            return;
        }
        busy = "no";
        if not ok {
            error = "Email or password is wrong. Passwords are case-sensitive.";
            return;
        }
        navigate("/advisor");
    }

    <div style={PAGE}>
        <header>
            <Link to="/" style={{"textDecoration": "none"}} aria-label="Jaccepted home"><Logo size={36} /></Link>
            <p style={LEDE | {"marginTop": "0.9rem"}}>Sign in to keep your profile and college list with your account.</p>
        </header>
        <main style={CARD}>
            <h2 style={SECTION_TITLE}>Sign in</h2>
            <p style={LEDE}>Use the email and password you created for Jaccepted.</p>
            {error and <p style={BANNER} role="alert">{error}</p>}
            <div style={STACK}>
                <TextField
                    id="login-email"
                    label="Email"
                    value={email}
                    onValue={lambda (value: str) { email = value; error = ""; }}
                    required={True}
                    placeholder="you@school.edu"
                    input_mode="email"
                />
                <TextField
                    id="login-password"
                    label="Password"
                    value={password}
                    onValue={lambda (value: str) { password = value; error = ""; }}
                    required={True}
                    hint="At least 6 characters."
                    input_type="password"
                />
                <div style={NAV}>
                    <button type="button" style={PRIMARY} disabled={busy == "yes"} onClick={lambda { submit(); }}>
                        {"Signing in…" if busy == "yes" else "Sign in"}
                    </button>
                    <Link style={SECONDARY} to="/signup">Create Account</Link>
                </div>
                <p style={HINT}><Link style={LINK} to="/">Back to home</Link></p>
            </div>
        </main>
    </div>
}

def:pub SignupForm -> JsxElement {
    has email: str = "",
        password: str = "",
        confirm: str = "",
        error: str = "",
        busy: str = "no";

    navigate = useNavigate();

    async def submit -> None {
        if busy == "yes" {
            return;
        }
        if not valid_email(email) {
            error = "Enter a valid email address.";
            return;
        }
        if len(password) < 6 {
            error = "Password must be at least 6 characters.";
            return;
        }
        if password != confirm {
            error = "Passwords do not match.";
            return;
        }
        busy = "yes";
        error = "";
        signup_result: SignupResult | None = None;
        login_ok: bool = False;
        identity = {"type": "email", "value": email.strip()};
        try {
            signup_result = await jacSignup([identity], password);
        } except Exception {
            busy = "no";
            error = "Could not create the account. Try again.";
            return;
        }
        if signup_result is None or not signup_result.success {
            busy = "no";
            error = "Could not create the account. That email may already be in use.";
            return;
        }
        try {
            login_ok = await jacLogin(identity, password);
        } except Exception {
            busy = "no";
            error = "Account created, but sign in failed. Try Sign in.";
            return;
        }
        busy = "no";
        if not login_ok {
            error = "Account created, but sign in failed. Try Sign in.";
            return;
        }
        navigate("/intake");
    }

    <div style={PAGE}>
        <header>
            <Link to="/" style={{"textDecoration": "none"}} aria-label="Jaccepted home"><Logo size={36} /></Link>
        </header>
        <main style={CARD}>
            <h2 style={SECTION_TITLE | {"textAlign": "center"}}>Create Account</h2>
            {error and <p style={BANNER} role="alert">{error}</p>}
            <div style={STACK}>
                <TextField
                    id="signup-email"
                    label="Email"
                    value={email}
                    onValue={lambda (value: str) { email = value; error = ""; }}
                    required={True}
                    marked={False}
                    input_mode="email"
                />
                <TextField
                    id="signup-password"
                    label="Password"
                    value={password}
                    onValue={lambda (value: str) { password = value; error = ""; }}
                    required={True}
                    marked={False}
                    input_type="password"
                />
                <TextField
                    id="signup-confirm"
                    label="Confirm password"
                    value={confirm}
                    onValue={lambda (value: str) { confirm = value; error = ""; }}
                    required={True}
                    marked={False}
                    input_type="password"
                />
                <div style={NAV}>
                    <button type="button" style={PRIMARY} disabled={busy == "yes"} onClick={lambda { submit(); }}>
                        {"Creating…" if busy == "yes" else "Create Account"}
                    </button>
                    <Link style={SECONDARY} to="/login">Sign in</Link>
                </div>
                <p style={HINT}><Link style={LINK} to="/">Back to home</Link></p>
            </div>
        </main>
    </div>
}
