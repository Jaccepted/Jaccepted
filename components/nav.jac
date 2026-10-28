"""Top navigation shared by the signed-in pages, in the style of the Common App header.

It also carries the light/dark toggle, sign out, and the advisor chat bubble.
"""

import from "@jac/runtime" { Link, jacLogout, useNavigate }
import from .logo { Logo }
import from .theme_toggle { ThemeToggle }
import from .chat_bubble { ChatBubble }
import from ..theme { TOPBAR, TOPBAR_INNER, TOPBAR_LINK, TOPBAR_LINK_ON, TOPBAR_LINKS }

# Per-student data kept in this browser. Cleared on sign out so the next person
# on a shared computer starts fresh. The light/dark choice is kept.
glob STUDENT_KEYS: list[str] = ["jaccepted.intake", "jaccepted.saved", "jaccepted.dismissed", "jaccepted.advisor", "jaccepted.essay_notes"];

"""Sign out and remove this student's data from the browser. Every sign-out button uses this."""
def:pub sign_out_and_forget -> None {
    jacLogout();
    try {
        for key in STUDENT_KEYS {
            localStorage.removeItem(key);
        }
    } except Exception {
        return;
    }
}

def:pub TopNav(current: str, saved_count: int = -1) -> JsxElement {
    navigate = useNavigate();

    def sign_out -> None {
        sign_out_and_forget();
        navigate("/");
    }

    colleges = "My Colleges" if saved_count < 0 else "My Colleges (" + str(saved_count) + ")";
    links = [
        ["advisor", "/advisor", "Advisor"],
        ["my-list", "/my-list", colleges],
        ["results", "/results", "Explore"],
        ["intake", "/intake", "Profile"]
    ];
    <>
        <header style={TOPBAR}>
            <div style={TOPBAR_INNER}>
                <Link to="/advisor" style={{"textDecoration": "none"}} aria-label="Jaccepted home">
                    <Logo size={36} />
                </Link>
                <div style={{"display": "flex", "alignItems": "center", "flexWrap": "wrap", "gap": "0.25rem 1rem"}}>
                    <nav aria-label="Main">
                        <ul style={TOPBAR_LINKS}>
                            {for link in links {
                                <li key={link[0]}>
                                    <Link
                                        to={link[1]}
                                        style={TOPBAR_LINK_ON if link[0] == current else TOPBAR_LINK}
                                        aria-current={"page" if link[0] == current else "false"}
                                    >
                                        {link[2]}
                                    </Link>
                                </li>
                            }}
                        </ul>
                    </nav>
                    <div style={{"display": "flex", "alignItems": "center", "gap": "0.5rem"}}>
                        <ThemeToggle />
                        <button
                            type="button"
                            onClick={sign_out}
                            style={{"minHeight": "40px", "padding": "0 0.85rem", "borderRadius": "999px", "border": "1px solid var(--border)", "background": "var(--surface)", "color": "var(--text)", "font": "inherit", "fontWeight": "600", "cursor": "pointer"}}
                        >
                            Sign out
                        </button>
                    </div>
                </div>
            </div>
        </header>
        {current != "advisor" and <ChatBubble />}
    </>
}
