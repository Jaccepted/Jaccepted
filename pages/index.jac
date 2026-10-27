"""Start page: what Jaccepted does, then account actions."""

import from "@jac/runtime" { Link, jacIsLoggedIn, jacLogout, useNavigate }
import from ..components.logo { Logo }
import from ..components.theme_toggle { ThemeToggle }
import from ..theme {
    HOME,
    HOME_ACTIONS,
    HOME_CREATE,
    HOME_SIGNIN,
    HOME_TAGLINE,
    HOME_TITLE,
    TOPBAR,
    TOPBAR_INNER,
    TOPBAR_LINK,
    Shell
}

glob STEPS: list[list[str]] = [
    ["1", "Tell us about you", "Grades, test scores, majors, and what you want in a campus and a price."],
    ["2", "Ask the advisor", "Describe the list you want. The AI advisor searches real college data and shows its work."],
    ["3", "Build a balanced list", "Save reach, target and likely schools, and refine the list in conversation."]
];

def:pub Home -> JsxPage {
    has signed_in: bool = False;

    navigate = useNavigate();

    can with entry {
        signed_in = jacIsLoggedIn();
    }

    def sign_out -> None {
        jacLogout();
        signed_in = False;
        navigate("/");
    }

    <Shell>
        <header style={TOPBAR}>
            <div style={TOPBAR_INNER}>
                <Logo size={36} />
                <div style={{"display": "flex", "alignItems": "center", "gap": "1rem"}}>
                    <ThemeToggle />
                    {if signed_in {
                        <button type="button" style={TOPBAR_LINK | {"background": "none", "border": "0", "font": "inherit", "cursor": "pointer"}} onClick={sign_out}>Sign out</button>
                    } else {
                        <Link style={TOPBAR_LINK} to="/login">Sign in</Link>
                    }}
                </div>
            </div>
        </header>
        <main style={HOME}>
            <h1 style={HOME_TITLE}>Find the colleges that fit you.</h1>
            <p style={HOME_TAGLINE}>
                An AI advisor builds your college list from real admissions data, explains every pick, and keeps it balanced. No guesses about your odds. Built entirely in Jac.
            </p>
            <div style={HOME_ACTIONS}>
                {if signed_in {
                    <>
                        <Link style={HOME_CREATE} to="/advisor">Open your advisor</Link>
                        <Link style={HOME_SIGNIN} to="/intake">My profile</Link>
                    </>
                } else {
                    <Link style={HOME_CREATE} to="/signup">Create Account</Link>
                }}
            </div>
            <ol style={{"listStyle": "none", "padding": "0", "margin": "3rem 0 0", "display": "grid", "gridTemplateColumns": "repeat(auto-fit, minmax(14rem, 1fr))", "gap": "1rem", "maxWidth": "60rem", "width": "100%", "textAlign": "left"}}>
                {for step in STEPS {
                    <li key={step[0]} data-glow="true" style={{"border": "1px solid var(--border)", "borderRadius": "12px", "padding": "1.1rem", "background": "var(--surface)", "boxShadow": "var(--shadow)"}}>
                        <span style={{"display": "inline-flex", "alignItems": "center", "justifyContent": "center", "width": "2rem", "height": "2rem", "borderRadius": "999px", "background": "var(--tint)", "color": "var(--accent-text)", "fontWeight": "700"}}>{step[0]}</span>
                        <h2 style={{"margin": "0.7rem 0 0.3rem", "fontSize": "1.1rem"}}>{step[1]}</h2>
                        <p style={{"margin": "0", "color": "var(--muted)"}}>{step[2]}</p>
                    </li>
                }}
            </ol>
        </main>
    </Shell>
}
