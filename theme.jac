"""Page colors and layout, expressed as element styles."""

def:pub Shell(children: any) -> JsxElement {
    can with entry {
        document.body.style.setProperty("margin", "0");
        document.body.style.setProperty("background", "#f3efe4");
        document.body.style.setProperty("color", "#1b2430");
        document.body.style.setProperty("font-family", "Avenir Next, Segoe UI, sans-serif");
        document.body.style.setProperty("font-size", "16px");
        document.body.style.setProperty("line-height", "1.45");
    }
    <>{children}</>
}

glob:pub HOME: dict[str, str] = {
    "minHeight": "100vh",
    "display": "flex",
    "flexDirection": "column",
    "alignItems": "center",
    "justifyContent": "center",
    "padding": "2rem 1.25rem 3rem",
    "textAlign": "center",
    "boxSizing": "border-box"
};

glob:pub HOME_TITLE: dict[str, str] = {
    "margin": "0",
    "fontFamily": "Palatino, Iowan Old Style, Georgia, serif",
    "fontSize": "4rem",
    "fontWeight": "600",
    "lineHeight": "1",
    "letterSpacing": "-0.02em"
};

glob:pub HOME_TAGLINE: dict[str, str] = {
    "margin": "0.9rem 0 0",
    "maxWidth": "22rem",
    "color": "#5c6570",
    "fontSize": "1.125rem"
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
    "background": "#0f5c4c",
    "color": "#f6f3ea"
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
    "background": "#fffdf8",
    "color": "#1b2430",
    "border": "1px solid #d8d0c2"
};

glob:pub PAGE: dict[str, str] = {
    "maxWidth": "42rem",
    "margin": "0 auto",
    "padding": "1.5rem 1rem 3rem",
    "boxSizing": "border-box"
};

glob:pub EYEBROW: dict[str, str] = {
    "margin": "0",
    "color": "#0f5c4c",
    "fontSize": "0.8rem",
    "fontWeight": "700",
    "letterSpacing": "0.04em",
    "textTransform": "uppercase"
};

glob:pub TITLE: dict[str, str] = {
    "margin": "0.2rem 0 0.4rem",
    "fontFamily": "Palatino, Iowan Old Style, Georgia, serif",
    "fontSize": "2.4rem",
    "fontWeight": "600",
    "lineHeight": "1.1"
};

glob:pub LEDE: dict[str, str] = {
    "margin": "0",
    "color": "#5c6570"
};

glob:pub STEPS: dict[str, str] = {
    "display": "flex",
    "gap": "0.4rem",
    "margin": "1.25rem 0 1rem",
    "padding": "0",
    "listStyle": "none",
    "overflowX": "auto"
};

glob:pub CARD: dict[str, str] = {
    "background": "#fffdf8",
    "border": "1px solid #d8d0c2",
    "borderRadius": "16px",
    "padding": "1.1rem 1rem 1rem"
};

glob:pub SECTION_TITLE: dict[str, str] = {
    "margin": "0 0 0.35rem",
    "fontFamily": "Palatino, Iowan Old Style, Georgia, serif",
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
    "color": "#8e2432"
};

glob:pub OPT: dict[str, str] = {
    "marginLeft": "0.45rem",
    "fontSize": "0.75rem",
    "fontWeight": "650",
    "letterSpacing": "0.02em",
    "textTransform": "uppercase",
    "color": "#5c6570"
};

glob:pub CONTROL: dict[str, str] = {
    "width": "100%",
    "minHeight": "48px",
    "padding": "0.55rem 0.7rem",
    "border": "1px solid #d8d0c2",
    "borderRadius": "10px",
    "background": "white",
    "color": "#1b2430",
    "font": "inherit",
    "boxSizing": "border-box"
};

glob:pub CONTROL_OFF: dict[str, str] = {
    "width": "100%",
    "minHeight": "48px",
    "padding": "0.55rem 0.7rem",
    "border": "1px solid #d8d0c2",
    "borderRadius": "10px",
    "background": "#f6f3ec",
    "color": "#5c6570",
    "font": "inherit",
    "boxSizing": "border-box"
};

glob:pub HINT: dict[str, str] = {
    "margin": "0",
    "color": "#5c6570",
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
    "border": "1px solid #d8d0c2",
    "borderRadius": "999px",
    "background": "white",
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
    "background": "#fdecee",
    "color": "#8e2432"
};

glob:pub SUCCESS: dict[str, str] = {
    "margin": "0.8rem 0 0",
    "padding": "0.7rem 0.8rem",
    "borderRadius": "10px",
    "background": "#e5f4ef",
    "color": "#0f5c4c"
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
    "background": "#0f5c4c",
    "color": "#f6f3ea"
};

glob:pub SECONDARY: dict[str, str] = {
    "minHeight": "48px",
    "borderRadius": "10px",
    "font": "inherit",
    "cursor": "pointer",
    "padding": "0.65rem 1rem",
    "background": "transparent",
    "color": "#1b2430",
    "border": "1px solid #d8d0c2"
};

glob:pub REVIEW_BLOCK: dict[str, str] = {
    "marginTop": "1rem",
    "paddingTop": "0.8rem",
    "borderTop": "1px solid #d8d0c2"
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
    "color": "#0f5c4c",
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
    "color": "#5c6570"
};

glob:pub DD: dict[str, str] = {
    "margin": "0"
};

def:pub step_look(current: bool, done: bool) -> dict[str, str] {
    background = "transparent";
    color = "#1b2430";
    border = "1px solid #d8d0c2";
    if current {
        background = "#0f5c4c";
        color = "#f6f3ea";
        border = "1px solid #0f5c4c";
    } elif done {
        color = "#0f5c4c";
        border = "1px solid #0f5c4c";
    }
    return {
        "border": border,
        "background": background,
        "color": color,
        "borderRadius": "999px",
        "padding": "0.45rem 0.75rem",
        "font": "inherit",
        "whiteSpace": "nowrap",
        "cursor": "pointer"
    };
}
