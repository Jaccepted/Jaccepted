"""Page colors and layout, expressed as element styles."""

import from .components.logo { FAVICON_SVG }

glob:pub THEME_CSS: str = """
:root {
    --bg: #ffffff; --surface: #ffffff; --surface-2: #f4f6f5; --surface-3: #eef1f0;
    --border: #dde2e0; --text: #1c2530; --muted: #5a6470;
    --accent: #0f5c4c; --accent-text: #0f5c4c; --accent-soft: #7cc4a8; --on-accent: #ffffff; --tint: #e9f3ef;
    --danger: #8e2432; --danger-bg: #fdecee; --warn: #8a5a00; --warn-bg: #fff4e0;
    --shadow: 0 1px 2px rgba(28, 37, 48, 0.05), 0 4px 16px -8px rgba(15, 92, 76, 0.18);
    --glow: 0 0 0 1px rgba(63, 163, 124, 0.25), 0 12px 32px -10px rgba(15, 92, 76, 0.45);
    --glow-strong: 0 6px 22px -4px rgba(31, 138, 108, 0.55);
    --hero-glow: rgba(63, 163, 124, 0.20);
    --logo-glow: rgba(15, 92, 76, 0.35);
    color-scheme: light;
}
:root[data-theme="dark"] {
    --bg: #0b1210; --surface: #121b18; --surface-2: #17231f; --surface-3: #1e2c27;
    --border: #2a3a34; --text: #e6ecea; --muted: #9aaaa4;
    --accent: #1f8a6c; --accent-text: #5fd6ad; --accent-soft: #3f8f74; --on-accent: #ffffff; --tint: #12302a;
    --danger: #ff8f9c; --danger-bg: #3a1c22; --warn: #f3c46e; --warn-bg: #3a2d12;
    --shadow: 0 1px 2px rgba(0, 0, 0, 0.4), 0 6px 20px -10px rgba(0, 0, 0, 0.6);
    --glow: 0 0 0 1px rgba(95, 214, 173, 0.30), 0 12px 38px -8px rgba(95, 214, 173, 0.35);
    --glow-strong: 0 0 26px -2px rgba(95, 214, 173, 0.55);
    --hero-glow: rgba(95, 214, 173, 0.18);
    --logo-glow: rgba(95, 214, 173, 0.45);
    color-scheme: dark;
}
@media (prefers-color-scheme: dark) {
    :root:not([data-theme="light"]) {
        --bg: #0b1210; --surface: #121b18; --surface-2: #17231f; --surface-3: #1e2c27;
    --border: #2a3a34; --text: #e6ecea; --muted: #9aaaa4;
    --accent: #1f8a6c; --accent-text: #5fd6ad; --accent-soft: #3f8f74; --on-accent: #ffffff; --tint: #12302a;
    --danger: #ff8f9c; --danger-bg: #3a1c22; --warn: #f3c46e; --warn-bg: #3a2d12;
    --shadow: 0 1px 2px rgba(0, 0, 0, 0.4), 0 6px 20px -10px rgba(0, 0, 0, 0.6);
    --glow: 0 0 0 1px rgba(95, 214, 173, 0.30), 0 12px 38px -8px rgba(95, 214, 173, 0.35);
    --glow-strong: 0 0 26px -2px rgba(95, 214, 173, 0.55);
    --hero-glow: rgba(95, 214, 173, 0.18);
    --logo-glow: rgba(95, 214, 173, 0.45);
    color-scheme: dark;
    }
}
@keyframes jac-spin { to { transform: rotate(360deg); } }
@keyframes jac-pulse { 0%, 100% { box-shadow: 0 0 0 0 rgba(63, 163, 124, 0.0); } 50% { box-shadow: 0 0 22px 4px rgba(63, 163, 124, 0.45); } }
@keyframes jac-rise { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: none; } }
html, body { background: var(--bg); color: var(--text); }
*:focus-visible { outline: 2px solid var(--accent-text); outline-offset: 2px; box-shadow: var(--glow); }
button, a, input, select, textarea { transition: box-shadow 0.2s, filter 0.2s, border-color 0.2s, background 0.2s; }
button:not(:disabled):hover { filter: brightness(1.08); }
input, select, textarea { color: var(--text); }
input::placeholder, textarea::placeholder { color: var(--muted); opacity: 0.8; }
[data-glow] { transition: box-shadow 0.25s, border-color 0.25s; }
[data-glow]:hover { box-shadow: var(--glow); border-color: var(--accent-soft); }
""";

def:pub Shell(children: any) -> JsxElement {
    can with entry {
        head: any = document.head;
        if not document.getElementById("jaccepted-theme") {
            sheet: any = document.createElement("style");
            sheet.setAttribute("id", "jaccepted-theme");
            sheet.textContent = THEME_CSS;
            head.appendChild(sheet);
        }
        try {
            chosen = localStorage.getItem("jaccepted.theme");
            if chosen == "dark" or chosen == "light" {
                document.documentElement.setAttribute("data-theme", chosen);
            }
        } except Exception {
            chosen = "";
        }
        icon: any = document.querySelector("link[rel='icon']");
        if not icon {
            icon = document.createElement("link");
            icon.setAttribute("rel", "icon");
            head.appendChild(icon);
        }
        icon.setAttribute("type", "image/svg+xml");
        icon.setAttribute("href", "data:image/svg+xml," + encodeURIComponent(FAVICON_SVG));
        document.body.style.setProperty("margin", "0");
        document.body.style.setProperty("background", "var(--bg)");
        document.body.style.setProperty("color", "var(--text)");
        document.body.style.setProperty("font-family", "'Helvetica Neue', Helvetica, Arial, sans-serif");
        document.body.style.setProperty("font-size", "16px");
        document.body.style.setProperty("line-height", "1.45");
    }
    <>
        {children}
        <footer style={FOOTER}>
            Built with <a href="https://www.jaseci.org" target="_blank" rel="noopener noreferrer" style={FOOTER_LINK}>Jac</a>, the open-source language from Jaseci for AI-native, full-stack apps.
        </footer>
    </>
}

glob:pub FOOTER: dict[str, str] = {
    "padding": "1.5rem 1rem 2rem",
    "borderTop": "1px solid var(--border)",
    "textAlign": "center",
    "color": "var(--muted)",
    "fontSize": "0.9rem"
};

glob:pub FOOTER_LINK: dict[str, str] = {
    "color": "var(--accent-text)",
    "fontWeight": "700"
};

glob:pub HOME: dict[str, str] = {
    "display": "flex",
    "flexDirection": "column",
    "alignItems": "center",
    "padding": "4.5rem 1rem 4rem",
    "textAlign": "center",
    "boxSizing": "border-box",
    "background": "radial-gradient(56rem 26rem at 50% -6rem, var(--hero-glow), transparent 70%)"
};

glob:pub HOME_TITLE: dict[str, str] = {
    "margin": "0",
    "fontFamily": "'Helvetica Neue', Helvetica, Arial, sans-serif",
    "fontSize": "clamp(2.2rem, 6vw, 3.4rem)",
    "fontWeight": "700",
    "lineHeight": "1.1",
    "letterSpacing": "-0.02em"
};

glob:pub HOME_TAGLINE: dict[str, str] = {
    "margin": "0.9rem 0 0",
    "maxWidth": "36rem",
    "color": "var(--muted)",
    "fontSize": "1.15rem"
};

glob:pub HOME_ACTIONS: dict[str, str] = {
    "display": "flex",
    "flexWrap": "wrap",
    "justifyContent": "center",
    "gap": "0.75rem",
    "marginTop": "2rem"
};

glob:pub HOME_CREATE: dict[str, str] = {
    "display": "inline-flex",
    "alignItems": "center",
    "justifyContent": "center",
    "minWidth": "10.5rem",
    "minHeight": "48px",
    "padding": "0.7rem 1.15rem",
    "borderRadius": "10px",
    "font": "inherit",
    "fontWeight": "650",
    "textDecoration": "none",
    "cursor": "pointer",
    "border": "0",
    "background": "var(--accent)",
    "color": "var(--on-accent)",
    "boxShadow": "var(--glow-strong)"
};

glob:pub HOME_SIGNIN: dict[str, str] = {
    "display": "inline-flex",
    "alignItems": "center",
    "justifyContent": "center",
    "minWidth": "10.5rem",
    "minHeight": "48px",
    "padding": "0.7rem 1.15rem",
    "borderRadius": "10px",
    "font": "inherit",
    "fontWeight": "650",
    "textDecoration": "none",
    "cursor": "pointer",
    "background": "var(--surface)",
    "color": "var(--text)",
    "border": "1px solid var(--border)"
};

glob:pub PAGE: dict[str, str] = {
    "maxWidth": "52rem",
    "margin": "0 auto",
    "padding": "1.5rem 1rem 3rem",
    "boxSizing": "border-box"
};

glob:pub EYEBROW: dict[str, str] = {
    "margin": "0",
    "color": "var(--accent-text)",
    "fontSize": "0.8rem",
    "fontWeight": "700",
    "letterSpacing": "0.04em",
    "textTransform": "uppercase"
};

glob:pub TITLE: dict[str, str] = {
    "margin": "0.2rem 0 0.4rem",
    "fontFamily": "'Helvetica Neue', Helvetica, Arial, sans-serif",
    "fontSize": "2rem",
    "fontWeight": "700",
    "letterSpacing": "-0.01em",
    "lineHeight": "1.15"
};

glob:pub LEDE: dict[str, str] = {
    "margin": "0",
    "color": "var(--muted)"
};

glob:pub STEPS: dict[str, str] = {
    "flex": "0 1 15rem",
    "display": "flex",
    "flexDirection": "column",
    "margin": "0",
    "padding": "0.4rem 0",
    "listStyle": "none",
    "border": "1px solid var(--border)",
    "borderRadius": "12px",
    "background": "var(--surface)"
};

glob:pub INTAKE_PAGE: dict[str, str] = {
    "maxWidth": "64rem",
    "margin": "0 auto",
    "padding": "1.75rem 1rem 3rem",
    "boxSizing": "border-box"
};

glob:pub INTAKE_LAYOUT: dict[str, str] = {
    "display": "flex",
    "flexWrap": "wrap",
    "gap": "1.25rem",
    "alignItems": "flex-start"
};

def:pub step_dot(done: bool) -> dict[str, str] {
    return {
        "display": "inline-flex",
        "alignItems": "center",
        "justifyContent": "center",
        "flexShrink": "0",
        "width": "1.6rem",
        "height": "1.6rem",
        "borderRadius": "999px",
        "fontSize": "0.85rem",
        "fontWeight": "700",
        "background": "var(--accent)" if done else "var(--surface-3)",
        "color": "var(--on-accent)" if done else "var(--muted)"
    };
}

glob:pub CARD: dict[str, str] = {
    "background": "var(--surface)",
    "border": "1px solid var(--border)",
    "borderRadius": "12px",
    "padding": "1.25rem",
    "boxShadow": "var(--shadow)"
};

glob:pub SECTION_TITLE: dict[str, str] = {
    "margin": "0 0 0.35rem",
    "fontFamily": "'Helvetica Neue', Helvetica, Arial, sans-serif",
    "fontSize": "1.6rem"
};

glob:pub H3: dict[str, str] = {
    "margin": "0",
    "fontSize": "1rem"
};

glob:pub STACK: dict[str, str] = {
    "display": "flex",
    "flexDirection": "column",
    "gap": "0.85rem",
    "marginTop": "1rem"
};

glob:pub GRID: dict[str, str] = {
    "display": "grid",
    "gridTemplateColumns": "repeat(auto-fit, minmax(16rem, 1fr))",
    "gap": "0.85rem 1rem"
};

glob:pub FIELD: dict[str, str] = {
    "display": "flex",
    "flexDirection": "column",
    "gap": "0.3rem"
};

glob:pub LABEL: dict[str, str] = {
    "fontWeight": "650"
};

glob:pub REQ: dict[str, str] = {
    "marginLeft": "0.45rem",
    "fontSize": "0.75rem",
    "fontWeight": "650",
    "letterSpacing": "0.02em",
    "textTransform": "uppercase",
    "color": "var(--danger)"
};

glob:pub OPT: dict[str, str] = {
    "marginLeft": "0.45rem",
    "fontSize": "0.75rem",
    "fontWeight": "650",
    "letterSpacing": "0.02em",
    "textTransform": "uppercase",
    "color": "var(--muted)"
};

glob:pub CONTROL: dict[str, str] = {
    "width": "100%",
    "minHeight": "48px",
    "padding": "0.55rem 0.7rem",
    "border": "1px solid var(--border)",
    "borderRadius": "10px",
    "background": "var(--surface)",
    "color": "var(--text)",
    "font": "inherit",
    "boxSizing": "border-box"
};

glob:pub CONTROL_OFF: dict[str, str] = {
    "width": "100%",
    "minHeight": "48px",
    "padding": "0.55rem 0.7rem",
    "border": "1px solid var(--border)",
    "borderRadius": "10px",
    "background": "var(--surface-2)",
    "color": "var(--muted)",
    "font": "inherit",
    "boxSizing": "border-box"
};

glob:pub CONTROL_OPEN: dict[str, str] = {
    "borderColor": "var(--accent)",
    "borderBottomLeftRadius": "0",
    "borderBottomRightRadius": "0",
    "outline": "none"
};

glob:pub SUGGEST_LIST: dict[str, str] = {
    "listStyle": "none",
    "margin": "-0.3rem 0 0",
    "padding": "0.25rem",
    "maxHeight": "15rem",
    "overflowY": "auto",
    "border": "1px solid var(--accent)",
    "borderTop": "1px solid var(--surface-3)",
    "borderRadius": "0 0 10px 10px",
    "background": "var(--surface)",
    "boxSizing": "border-box"
};

glob:pub SUGGEST_ITEM: dict[str, str] = {
    "padding": "0.6rem 0.6rem",
    "borderRadius": "7px",
    "cursor": "pointer",
    "color": "var(--text)"
};

glob:pub SUGGEST_ITEM_ON: dict[str, str] = {
    "padding": "0.6rem 0.6rem",
    "borderRadius": "7px",
    "cursor": "pointer",
    "color": "var(--accent-text)",
    "background": "var(--tint)",
    "fontWeight": "600"
};

glob:pub HINT: dict[str, str] = {
    "margin": "0",
    "color": "var(--muted)",
    "fontSize": "0.9rem"
};

glob:pub LEGEND: dict[str, str] = {
    "fontWeight": "650"
};

glob:pub FIELDSET: dict[str, str] = {
    "margin": "0",
    "padding": "0",
    "border": "0"
};

glob:pub CHOICES: dict[str, str] = {
    "display": "flex",
    "flexWrap": "wrap",
    "gap": "0.5rem"
};

glob:pub CHOICE: dict[str, str] = {
    "display": "flex",
    "alignItems": "center",
    "gap": "0.45rem",
    "minHeight": "44px",
    "margin": "0",
    "padding": "0.35rem 0.7rem",
    "border": "1px solid var(--border)",
    "borderRadius": "999px",
    "background": "var(--surface)",
    "fontWeight": "500"
};

glob:pub CHOICE_INPUT: dict[str, str] = {
    "width": "1.05rem",
    "height": "1.05rem",
    "minHeight": "0",
    "margin": "0"
};

glob:pub BANNER: dict[str, str] = {
    "margin": "0.8rem 0 0",
    "padding": "0.7rem 0.8rem",
    "borderRadius": "10px",
    "background": "var(--danger-bg)",
    "color": "var(--danger)"
};

glob:pub SUCCESS: dict[str, str] = {
    "margin": "0.8rem 0 0",
    "padding": "0.7rem 0.8rem",
    "borderRadius": "10px",
    "background": "var(--tint)",
    "color": "var(--accent-text)"
};

glob:pub TOPBAR: dict[str, str] = {
    "position": "sticky",
    "top": "0",
    "zIndex": "10",
    "background": "var(--surface)",
    "borderBottom": "1px solid var(--border)",
    "boxShadow": "var(--shadow)"
};

glob:pub TOPBAR_INNER: dict[str, str] = {
    "maxWidth": "72rem",
    "margin": "0 auto",
    "padding": "0 1rem",
    "display": "flex",
    "alignItems": "center",
    "justifyContent": "space-between",
    "flexWrap": "wrap",
    "gap": "0.25rem 1.5rem",
    "minHeight": "64px",
    "boxSizing": "border-box"
};

glob:pub TOPBAR_LINKS: dict[str, str] = {
    "display": "flex",
    "flexWrap": "wrap",
    "gap": "0 1rem",
    "listStyle": "none",
    "margin": "0",
    "padding": "0"
};

glob:pub TOPBAR_LINK: dict[str, str] = {
    "display": "inline-flex",
    "alignItems": "center",
    "minHeight": "48px",
    "borderBottom": "3px solid transparent",
    "color": "var(--text)",
    "fontWeight": "600",
    "fontSize": "0.95rem",
    "textDecoration": "none"
};

glob:pub TOPBAR_LINK_ON: dict[str, str] = {
    "display": "inline-flex",
    "alignItems": "center",
    "minHeight": "48px",
    "borderBottom": "3px solid var(--accent)",
    "color": "var(--accent-text)",
    "fontWeight": "700",
    "fontSize": "0.95rem",
    "textDecoration": "none"
};

glob:pub NAV: dict[str, str] = {
    "display": "flex",
    "gap": "0.6rem",
    "marginTop": "1.1rem"
};

glob:pub PRIMARY: dict[str, str] = {
    "minHeight": "48px",
    "borderRadius": "10px",
    "font": "inherit",
    "cursor": "pointer",
    "border": "0",
    "padding": "0.65rem 1rem",
    "background": "var(--accent)",
    "color": "var(--on-accent)",
    "boxShadow": "var(--glow-strong)"
};

glob:pub SECONDARY: dict[str, str] = {
    "minHeight": "48px",
    "borderRadius": "10px",
    "font": "inherit",
    "cursor": "pointer",
    "padding": "0.65rem 1rem",
    "background": "transparent",
    "color": "var(--text)",
    "border": "1px solid var(--border)"
};

glob:pub REVIEW_BLOCK: dict[str, str] = {
    "marginTop": "1rem",
    "paddingTop": "0.8rem",
    "borderTop": "1px solid var(--border)"
};

glob:pub REVIEW_HEAD: dict[str, str] = {
    "display": "flex",
    "alignItems": "center",
    "justifyContent": "space-between",
    "gap": "0.75rem"
};

glob:pub EDIT: dict[str, str] = {
    "minHeight": "48px",
    "borderRadius": "10px",
    "font": "inherit",
    "cursor": "pointer",
    "border": "0",
    "background": "transparent",
    "color": "var(--accent-text)",
    "padding": "0.2rem 0",
    "textDecoration": "underline"
};

glob:pub REVIEW: dict[str, str] = {
    "display": "grid",
    "gridTemplateColumns": "minmax(8rem, 40%) 1fr",
    "gap": "0.35rem 0.75rem",
    "margin": "0.45rem 0 0"
};

glob:pub DT: dict[str, str] = {
    "color": "var(--muted)"
};

glob:pub DD: dict[str, str] = {
    "margin": "0"
};

def:pub step_look(current: bool, done: bool) -> dict[str, str] {
    return {
        "display": "flex",
        "alignItems": "center",
        "gap": "0.7rem",
        "width": "100%",
        "minHeight": "48px",
        "padding": "0.4rem 0.9rem",
        "border": "0",
        "borderLeft": "4px solid var(--accent)" if current else "4px solid transparent",
        "background": "var(--tint)" if current else "transparent",
        "color": "var(--accent-text)" if current or done else "var(--text)",
        "font": "inherit",
        "fontWeight": "700" if current else "500",
        "textAlign": "left",
        "cursor": "pointer"
    };
}

glob:pub BUCKET_HEAD: dict[str, str] = {
    "display": "flex",
    "alignItems": "baseline",
    "justifyContent": "space-between",
    "gap": "0.75rem",
    "flexWrap": "wrap"
};

glob:pub RESULT: dict[str, str] = {
    "padding": "0.85rem 0",
    "borderTop": "1px solid var(--border)"
};

glob:pub RESULT_HEAD: dict[str, str] = {
    "display": "flex",
    "alignItems": "flex-start",
    "justifyContent": "space-between",
    "gap": "0.75rem"
};

glob:pub RESULT_NAME: dict[str, str] = {
    "margin": "0",
    "fontSize": "1.05rem",
    "fontWeight": "650"
};

glob:pub FIT: dict[str, str] = {
    "flexShrink": "0",
    "minWidth": "3.2rem",
    "padding": "0.2rem 0.5rem",
    "borderRadius": "8px",
    "background": "var(--tint)",
    "color": "var(--accent-text)",
    "fontWeight": "700",
    "textAlign": "center"
};

glob:pub FACTS: dict[str, str] = {
    "display": "flex",
    "flexWrap": "wrap",
    "gap": "0.25rem 1rem",
    "margin": "0.3rem 0 0",
    "color": "var(--muted)",
    "fontSize": "0.9rem"
};

glob:pub REASONS: dict[str, str] = {
    "margin": "0.45rem 0 0",
    "paddingLeft": "1.1rem",
    "fontSize": "0.95rem"
};

glob:pub BADGE: dict[str, str] = {
    "display": "inline-block",
    "marginLeft": "0.5rem",
    "padding": "0.05rem 0.45rem",
    "borderRadius": "999px",
    "background": "var(--accent)",
    "color": "var(--on-accent)",
    "fontSize": "0.72rem",
    "fontWeight": "700",
    "letterSpacing": "0.03em",
    "textTransform": "uppercase",
    "verticalAlign": "middle"
};

glob:pub LINK: dict[str, str] = {
    "color": "var(--accent-text)",
    "fontWeight": "650"
};

def:pub bucket_look(bucket: str) -> dict[str, str] {
    color = "var(--accent-text)";
    if bucket == "reach" {
        color = "var(--danger)";
    } elif bucket == "target" {
        color = "var(--warn)";
    }
    return {
        "margin": "0",
        "fontFamily": "'Helvetica Neue', Helvetica, Arial, sans-serif",
        "fontSize": "1.5rem",
        "color": color
    };
}

glob:pub LINK_BUTTON: dict[str, str] = {
    "border": "0",
    "padding": "0",
    "background": "transparent",
    "color": "var(--accent-text)",
    "font": "inherit",
    "fontWeight": "650",
    "textDecoration": "underline",
    "cursor": "pointer"
};

glob:pub TOOLBAR: dict[str, str] = {
    "display": "flex",
    "flexWrap": "wrap",
    "alignItems": "flex-end",
    "gap": "0.6rem",
    "margin": "0 0 0.4rem"
};

glob:pub TOOL_LABEL: dict[str, str] = {
    "display": "flex",
    "flexDirection": "column",
    "gap": "0.25rem",
    "fontWeight": "650",
    "fontSize": "0.9rem"
};

glob:pub TOOL_INPUT: dict[str, str] = {
    "minHeight": "48px",
    "minWidth": "12rem",
    "padding": "0.55rem 0.7rem",
    "border": "1px solid var(--border)",
    "borderRadius": "10px",
    "background": "var(--surface)",
    "color": "var(--text)",
    "font": "inherit",
    "fontWeight": "400",
    "boxSizing": "border-box"
};

glob:pub DETAIL_GRID: dict[str, str] = {
    "display": "grid",
    "gridTemplateColumns": "repeat(auto-fit, minmax(17rem, 1fr))",
    "gap": "1rem",
    "alignItems": "start"
};

glob:pub STAT_ROW: dict[str, str] = {
    "display": "flex",
    "justifyContent": "space-between",
    "gap": "1rem",
    "padding": "0.3rem 0",
    "borderBottom": "1px solid var(--surface-2)",
    "fontSize": "0.92rem"
};

glob:pub STAT_LABEL: dict[str, str] = {
    "color": "var(--muted)"
};

glob:pub STAT_VALUE: dict[str, str] = {
    "fontWeight": "650",
    "textAlign": "right"
};

glob:pub RANGE_TRACK: dict[str, str] = {
    "position": "relative",
    "height": "10px",
    "margin": "1.4rem 0 0.7rem",
    "borderRadius": "999px",
    "background": "var(--surface-2)"
};

def:pub range_fill(low_pct: float, high_pct: float) -> dict[str, str] {
    return {
        "position": "absolute",
        "top": "0",
        "bottom": "0",
        "left": str(low_pct) + "%",
        "width": str(max(high_pct - low_pct, 1.0)) + "%",
        "borderRadius": "999px",
        "background": "var(--accent)",
        "opacity": "0.55"
    };
}

def:pub range_marker(pct: float) -> dict[str, str] {
    return {
        "position": "absolute",
        "top": "-6px",
        "left": "calc(" + str(pct) + "% - 3px)",
        "width": "6px",
        "height": "22px",
        "borderRadius": "3px",
        "background": "var(--danger)"
    };
}

glob:pub WIDE_PAGE: dict[str, str] = {
    "maxWidth": "52rem",
    "margin": "0 auto",
    "padding": "1.75rem 1rem 3rem",
    "boxSizing": "border-box"
};

glob:pub ME_BUBBLE: dict[str, str] = {
    "alignSelf": "flex-end",
    "maxWidth": "85%",
    "padding": "0.7rem 0.95rem",
    "borderRadius": "16px 16px 4px 16px",
    "background": "var(--accent)",
    "color": "var(--on-accent)",
    "whiteSpace": "pre-wrap",
    "boxShadow": "var(--glow-strong)"
};

glob:pub AGENT_ROW: dict[str, str] = {
    "display": "flex",
    "gap": "0.75rem",
    "alignItems": "flex-start"
};

glob:pub AGENT_BODY: dict[str, str] = {
    "flex": "1",
    "minWidth": "0",
    "display": "flex",
    "flexDirection": "column",
    "gap": "0.75rem"
};

glob:pub STEP_BOX: dict[str, str] = {
    "border": "1px solid var(--border)",
    "borderRadius": "12px",
    "background": "var(--surface-2)",
    "padding": "0.55rem 0.8rem"
};

glob:pub STEP_LIST: dict[str, str] = {
    "listStyle": "none",
    "margin": "0.4rem 0 0",
    "padding": "0",
    "display": "flex",
    "flexDirection": "column",
    "gap": "0.3rem",
    "color": "var(--muted)",
    "fontSize": "0.92rem"
};

glob:pub PICK_LIST: dict[str, str] = {
    "listStyle": "none",
    "margin": "0",
    "padding": "0",
    "border": "1px solid var(--border)",
    "borderRadius": "12px",
    "overflow": "hidden"
};

glob:pub PICK_ROW: dict[str, str] = {
    "display": "flex",
    "alignItems": "center",
    "gap": "0.75rem",
    "padding": "0.75rem 0.9rem",
    "borderTop": "1px solid var(--border)",
    "background": "var(--surface)"
};

glob:pub PICK_TEXT: dict[str, str] = {
    "flex": "1",
    "minWidth": "0"
};

glob:pub PICK_NAME: dict[str, str] = {
    "color": "var(--text)",
    "fontWeight": "650",
    "textDecoration": "none"
};

glob:pub PICK_WHY: dict[str, str] = {
    "margin": "0.15rem 0 0",
    "color": "var(--muted)",
    "fontSize": "0.92rem"
};

glob:pub SAVE_BUTTON: dict[str, str] = {
    "flexShrink": "0",
    "minHeight": "40px",
    "padding": "0 0.85rem",
    "borderRadius": "8px",
    "border": "1px solid var(--accent)",
    "background": "var(--surface)",
    "color": "var(--accent-text)",
    "font": "inherit",
    "fontWeight": "600",
    "cursor": "pointer"
};

glob:pub SAVED_BUTTON: dict[str, str] = {
    "flexShrink": "0",
    "minHeight": "40px",
    "padding": "0 0.85rem",
    "borderRadius": "8px",
    "border": "1px solid var(--accent)",
    "background": "var(--accent)",
    "color": "var(--on-accent)",
    "font": "inherit",
    "fontWeight": "600",
    "cursor": "pointer",
    "boxShadow": "var(--glow-strong)"
};

glob:pub FOLLOW_UP: dict[str, str] = {
    "minHeight": "40px",
    "padding": "0.4rem 0.85rem",
    "borderRadius": "999px",
    "border": "1px solid var(--border)",
    "background": "var(--surface)",
    "color": "var(--accent-text)",
    "font": "inherit",
    "fontWeight": "600",
    "cursor": "pointer",
    "textAlign": "left"
};

glob:pub COMPOSER: dict[str, str] = {
    "position": "sticky",
    "bottom": "0",
    "background": "var(--surface)",
    "paddingTop": "0.75rem",
    "paddingBottom": "1rem",
    "borderTop": "1px solid var(--border)"
};

glob:pub COMPOSER_ROW: dict[str, str] = {
    "display": "flex",
    "gap": "0.5rem",
    "alignItems": "flex-end"
};

def:pub bucket_chip(bucket: str) -> dict[str, str] {
    background = "var(--tint)";
    color = "var(--accent-text)";
    if bucket == "reach" {
        background = "var(--danger-bg)";
        color = "var(--danger)";
    } elif bucket == "target" {
        background = "var(--warn-bg)";
        color = "var(--warn)";
    }
    return {
        "display": "inline-block",
        "padding": "0.1rem 0.5rem",
        "borderRadius": "999px",
        "background": background,
        "color": color,
        "fontSize": "0.78rem",
        "fontWeight": "700",
        "letterSpacing": "0.02em",
        "textTransform": "uppercase",
        "marginRight": "0.45rem",
        "verticalAlign": "middle"
    };
}
