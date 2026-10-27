"""Page colors and layout, expressed as element styles."""

import from .components.logo { FAVICON_SVG }

def:pub Shell(children: any) -> JsxElement {
    can with entry {
        head: any = document.head;
        icon: any = document.querySelector("link[rel='icon']");
        if not icon {
            icon = document.createElement("link");
            icon.setAttribute("rel", "icon");
            head.appendChild(icon);
        }
        icon.setAttribute("type", "image/svg+xml");
        icon.setAttribute("href", "data:image/svg+xml," + encodeURIComponent(FAVICON_SVG));
        document.body.style.setProperty("margin", "0");
        document.body.style.setProperty("background", "#ffffff");
        document.body.style.setProperty("color", "#1c2530");
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
    "borderTop": "1px solid #dde2e0",
    "textAlign": "center",
    "color": "#5a6470",
    "fontSize": "0.9rem"
};

glob:pub FOOTER_LINK: dict[str, str] = {
    "color": "#0f5c4c",
    "fontWeight": "700"
};

glob:pub HOME: dict[str, str] = {
    "display": "flex",
    "flexDirection": "column",
    "alignItems": "center",
    "padding": "4.5rem 1rem 4rem",
    "textAlign": "center",
    "boxSizing": "border-box"
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
    "color": "#5a6470",
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
    "background": "#0f5c4c",
    "color": "#ffffff"
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
    "background": "#ffffff",
    "color": "#1c2530",
    "border": "1px solid #dde2e0"
};

glob:pub PAGE: dict[str, str] = {
    "maxWidth": "52rem",
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
    "fontFamily": "'Helvetica Neue', Helvetica, Arial, sans-serif",
    "fontSize": "2rem",
    "fontWeight": "700",
    "letterSpacing": "-0.01em",
    "lineHeight": "1.15"
};

glob:pub LEDE: dict[str, str] = {
    "margin": "0",
    "color": "#5a6470"
};

glob:pub STEPS: dict[str, str] = {
    "flex": "0 1 15rem",
    "display": "flex",
    "flexDirection": "column",
    "margin": "0",
    "padding": "0.4rem 0",
    "listStyle": "none",
    "border": "1px solid #dde2e0",
    "borderRadius": "12px",
    "background": "#ffffff"
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
        "background": "#0f5c4c" if done else "#eef1f0",
        "color": "#ffffff" if done else "#5a6470"
    };
}

glob:pub CARD: dict[str, str] = {
    "background": "#ffffff",
    "border": "1px solid #dde2e0",
    "borderRadius": "12px",
    "padding": "1.25rem",
    "boxShadow": "0 1px 2px rgba(28, 37, 48, 0.04)"
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
    "color": "#8e2432"
};

glob:pub OPT: dict[str, str] = {
    "marginLeft": "0.45rem",
    "fontSize": "0.75rem",
    "fontWeight": "650",
    "letterSpacing": "0.02em",
    "textTransform": "uppercase",
    "color": "#5a6470"
};

glob:pub CONTROL: dict[str, str] = {
    "width": "100%",
    "minHeight": "48px",
    "padding": "0.55rem 0.7rem",
    "border": "1px solid #dde2e0",
    "borderRadius": "10px",
    "background": "white",
    "color": "#1c2530",
    "font": "inherit",
    "boxSizing": "border-box"
};

glob:pub CONTROL_OFF: dict[str, str] = {
    "width": "100%",
    "minHeight": "48px",
    "padding": "0.55rem 0.7rem",
    "border": "1px solid #dde2e0",
    "borderRadius": "10px",
    "background": "#f4f6f5",
    "color": "#5a6470",
    "font": "inherit",
    "boxSizing": "border-box"
};

glob:pub CONTROL_OPEN: dict[str, str] = {
    "borderColor": "#0f5c4c",
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
    "border": "1px solid #0f5c4c",
    "borderTop": "1px solid #eef1f0",
    "borderRadius": "0 0 10px 10px",
    "background": "white",
    "boxSizing": "border-box"
};

glob:pub SUGGEST_ITEM: dict[str, str] = {
    "padding": "0.6rem 0.6rem",
    "borderRadius": "7px",
    "cursor": "pointer",
    "color": "#1c2530"
};

glob:pub SUGGEST_ITEM_ON: dict[str, str] = {
    "padding": "0.6rem 0.6rem",
    "borderRadius": "7px",
    "cursor": "pointer",
    "color": "#0f5c4c",
    "background": "#e9f3ef",
    "fontWeight": "600"
};

glob:pub HINT: dict[str, str] = {
    "margin": "0",
    "color": "#5a6470",
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
    "border": "1px solid #dde2e0",
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
    "background": "#e9f3ef",
    "color": "#0f5c4c"
};

glob:pub TOPBAR: dict[str, str] = {
    "position": "sticky",
    "top": "0",
    "zIndex": "10",
    "background": "#ffffff",
    "borderBottom": "1px solid #dde2e0",
    "boxShadow": "0 1px 3px rgba(28, 37, 48, 0.06)"
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
    "color": "#1c2530",
    "fontWeight": "600",
    "fontSize": "0.95rem",
    "textDecoration": "none"
};

glob:pub TOPBAR_LINK_ON: dict[str, str] = {
    "display": "inline-flex",
    "alignItems": "center",
    "minHeight": "48px",
    "borderBottom": "3px solid #0f5c4c",
    "color": "#0f5c4c",
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
    "background": "#0f5c4c",
    "color": "#ffffff"
};

glob:pub SECONDARY: dict[str, str] = {
    "minHeight": "48px",
    "borderRadius": "10px",
    "font": "inherit",
    "cursor": "pointer",
    "padding": "0.65rem 1rem",
    "background": "transparent",
    "color": "#1c2530",
    "border": "1px solid #dde2e0"
};

glob:pub REVIEW_BLOCK: dict[str, str] = {
    "marginTop": "1rem",
    "paddingTop": "0.8rem",
    "borderTop": "1px solid #dde2e0"
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
    "color": "#5a6470"
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
        "borderLeft": "4px solid #0f5c4c" if current else "4px solid transparent",
        "background": "#e9f3ef" if current else "transparent",
        "color": "#0f5c4c" if current or done else "#1c2530",
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
    "borderTop": "1px solid #dde2e0"
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
    "background": "#e9f3ef",
    "color": "#0f5c4c",
    "fontWeight": "700",
    "textAlign": "center"
};

glob:pub FACTS: dict[str, str] = {
    "display": "flex",
    "flexWrap": "wrap",
    "gap": "0.25rem 1rem",
    "margin": "0.3rem 0 0",
    "color": "#5a6470",
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
    "background": "#0f5c4c",
    "color": "#ffffff",
    "fontSize": "0.72rem",
    "fontWeight": "700",
    "letterSpacing": "0.03em",
    "textTransform": "uppercase",
    "verticalAlign": "middle"
};

glob:pub LINK: dict[str, str] = {
    "color": "#0f5c4c",
    "fontWeight": "650"
};

def:pub bucket_look(bucket: str) -> dict[str, str] {
    color = "#0f5c4c";
    if bucket == "reach" {
        color = "#8e2432";
    } elif bucket == "target" {
        color = "#8a5a00";
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
    "color": "#0f5c4c",
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
    "border": "1px solid #dde2e0",
    "borderRadius": "10px",
    "background": "white",
    "color": "#1c2530",
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
    "borderBottom": "1px solid #f4f6f5",
    "fontSize": "0.92rem"
};

glob:pub STAT_LABEL: dict[str, str] = {
    "color": "#5a6470"
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
    "background": "#f4f6f5"
};

def:pub range_fill(low_pct: float, high_pct: float) -> dict[str, str] {
    return {
        "position": "absolute",
        "top": "0",
        "bottom": "0",
        "left": str(low_pct) + "%",
        "width": str(max(high_pct - low_pct, 1.0)) + "%",
        "borderRadius": "999px",
        "background": "#0f5c4c",
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
        "background": "#8e2432"
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
    "background": "#0f5c4c",
    "color": "#ffffff",
    "whiteSpace": "pre-wrap"
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
    "border": "1px solid #dde2e0",
    "borderRadius": "12px",
    "background": "#f4f6f5",
    "padding": "0.55rem 0.8rem"
};

glob:pub STEP_LIST: dict[str, str] = {
    "listStyle": "none",
    "margin": "0.4rem 0 0",
    "padding": "0",
    "display": "flex",
    "flexDirection": "column",
    "gap": "0.3rem",
    "color": "#5a6470",
    "fontSize": "0.92rem"
};

glob:pub PICK_LIST: dict[str, str] = {
    "listStyle": "none",
    "margin": "0",
    "padding": "0",
    "border": "1px solid #dde2e0",
    "borderRadius": "12px",
    "overflow": "hidden"
};

glob:pub PICK_ROW: dict[str, str] = {
    "display": "flex",
    "alignItems": "center",
    "gap": "0.75rem",
    "padding": "0.75rem 0.9rem",
    "borderTop": "1px solid #dde2e0",
    "background": "#ffffff"
};

glob:pub PICK_TEXT: dict[str, str] = {
    "flex": "1",
    "minWidth": "0"
};

glob:pub PICK_NAME: dict[str, str] = {
    "color": "#1c2530",
    "fontWeight": "650",
    "textDecoration": "none"
};

glob:pub PICK_WHY: dict[str, str] = {
    "margin": "0.15rem 0 0",
    "color": "#5a6470",
    "fontSize": "0.92rem"
};

glob:pub SAVE_BUTTON: dict[str, str] = {
    "flexShrink": "0",
    "minHeight": "40px",
    "padding": "0 0.85rem",
    "borderRadius": "8px",
    "border": "1px solid #0f5c4c",
    "background": "#ffffff",
    "color": "#0f5c4c",
    "font": "inherit",
    "fontWeight": "600",
    "cursor": "pointer"
};

glob:pub SAVED_BUTTON: dict[str, str] = {
    "flexShrink": "0",
    "minHeight": "40px",
    "padding": "0 0.85rem",
    "borderRadius": "8px",
    "border": "1px solid #0f5c4c",
    "background": "#0f5c4c",
    "color": "#ffffff",
    "font": "inherit",
    "fontWeight": "600",
    "cursor": "pointer"
};

glob:pub FOLLOW_UP: dict[str, str] = {
    "minHeight": "40px",
    "padding": "0.4rem 0.85rem",
    "borderRadius": "999px",
    "border": "1px solid #dde2e0",
    "background": "#ffffff",
    "color": "#0f5c4c",
    "font": "inherit",
    "fontWeight": "600",
    "cursor": "pointer",
    "textAlign": "left"
};

glob:pub COMPOSER: dict[str, str] = {
    "position": "sticky",
    "bottom": "0",
    "background": "#ffffff",
    "paddingTop": "0.75rem",
    "paddingBottom": "1rem",
    "borderTop": "1px solid #dde2e0"
};

glob:pub COMPOSER_ROW: dict[str, str] = {
    "display": "flex",
    "gap": "0.5rem",
    "alignItems": "flex-end"
};

def:pub bucket_chip(bucket: str) -> dict[str, str] {
    background = "#e9f3ef";
    color = "#0f5c4c";
    if bucket == "reach" {
        background = "#fdecee";
        color = "#8e2432";
    } elif bucket == "target" {
        background = "#fff4e0";
        color = "#8a5a00";
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
