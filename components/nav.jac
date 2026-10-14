"""Top navigation shared by the results and My List pages."""

import from "@jac/runtime" { Link }
import from ..theme { TOPBAR, TOPBAR_INNER, TOPBAR_LINK, TOPBAR_LINK_ON, TOPBAR_LINKS }

def:pub TopNav(current: str, saved_count: int) -> JsxElement {
    links = [
        ["results", "/results", "Results"],
        ["my-list", "/my-list", "My List (" + str(saved_count) + ")"],
        ["intake", "/intake", "Edit profile"]
    ];
    <nav style={TOPBAR} aria-label="Main">
        <div style={TOPBAR_INNER}>
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
        </div>
    </nav>
}
