"""Top navigation shared by the signed-in pages, in the style of the Common App header."""

import from "@jac/runtime" { Link }
import from .logo { Logo }
import from ..theme { TOPBAR, TOPBAR_INNER, TOPBAR_LINK, TOPBAR_LINK_ON, TOPBAR_LINKS }

def:pub TopNav(current: str, saved_count: int = -1) -> JsxElement {
    colleges = "My Colleges" if saved_count < 0 else "My Colleges (" + str(saved_count) + ")";
    links = [
        ["advisor", "/advisor", "Advisor"],
        ["my-list", "/my-list", colleges],
        ["results", "/results", "Explore"],
        ["intake", "/intake", "Profile"]
    ];
    <header style={TOPBAR}>
        <div style={TOPBAR_INNER}>
            <Link to="/advisor" style={{"textDecoration": "none"}} aria-label="Jaccepted home">
                <Logo size={36} />
            </Link>
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
        </div>
    </header>
}
