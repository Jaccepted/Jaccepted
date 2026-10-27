"""Switch between light and dark mode. The choice is remembered in this browser."""

def:pub ThemeToggle -> JsxElement {
    has dark: bool = False;

    can with entry {
        # Read the saved choice directly: this can run before Shell applies it.
        chosen: any = None;
        try {
            chosen = localStorage.getItem("jaccepted.theme");
        } except Exception {
            chosen = None;
        }
        if not chosen {
            chosen = document.documentElement.getAttribute("data-theme");
        }
        if chosen == "dark" or chosen == "light" {
            dark = chosen == "dark";
        } else {
            query: any = window.matchMedia("(prefers-color-scheme: dark)");
            dark = bool(query.matches);
        }
    }

    def flip -> None {
        dark = not dark;
        mode = "dark" if dark else "light";
        document.documentElement.setAttribute("data-theme", mode);
        try {
            localStorage.setItem("jaccepted.theme", mode);
        } except Exception {
            return;
        }
    }

    <button
        type="button"
        onClick={flip}
        aria-label={"Switch to light mode" if dark else "Switch to dark mode"}
        title={"Light mode" if dark else "Dark mode"}
        style={{
            "display": "inline-flex",
            "alignItems": "center",
            "justifyContent": "center",
            "width": "40px",
            "height": "40px",
            "borderRadius": "999px",
            "border": "1px solid var(--border)",
            "background": "var(--surface)",
            "color": "var(--accent-text)",
            "fontSize": "1.1rem",
            "cursor": "pointer"
        }}
    >
        {"☀" if dark else "☾"}
    </button>
}
