"""The advisor as a chat bubble in the lower right of every signed-in page."""

import from "@jac/runtime" { Link }
import from ..advisor_chat { AdvisorChat }
import from .logo { LogoMark }

glob BUBBLE_BUTTON: dict[str, str] = {
    "position": "fixed",
    "right": "20px",
    "bottom": "20px",
    "zIndex": "40",
    "width": "60px",
    "height": "60px",
    "borderRadius": "999px",
    "border": "0",
    "background": "var(--accent)",
    "color": "var(--on-accent)",
    "display": "inline-flex",
    "alignItems": "center",
    "justifyContent": "center",
    "cursor": "pointer",
    "boxShadow": "var(--glow-strong), 0 8px 24px rgba(0, 0, 0, 0.25)"
};

glob PANEL: dict[str, str] = {
    "position": "fixed",
    "right": "20px",
    "bottom": "92px",
    "zIndex": "40",
    "width": "min(400px, calc(100vw - 24px))",
    "height": "min(620px, calc(100vh - 120px))",
    "display": "flex",
    "flexDirection": "column",
    "background": "var(--surface)",
    "border": "1px solid var(--border)",
    "borderRadius": "16px",
    "boxShadow": "var(--glow), 0 24px 60px -12px rgba(0, 0, 0, 0.35)",
    "overflow": "hidden",
    "animation": "jac-rise 0.2s ease-out"
};

glob PANEL_HEAD: dict[str, str] = {
    "display": "flex",
    "alignItems": "center",
    "gap": "0.6rem",
    "padding": "0.75rem 0.9rem",
    "borderBottom": "1px solid var(--border)",
    "background": "var(--surface-2)"
};

glob PANEL_BODY: dict[str, str] = {
    "flex": "1",
    "overflowY": "auto",
    "padding": "0.9rem"
};

def ChatIcon -> JsxElement {
    <svg width="28" height="28" viewBox="0 0 24 24" aria-hidden="true">
        <path
            d="M4 5.5 A2.5 2.5 0 0 1 6.5 3 H17.5 A2.5 2.5 0 0 1 20 5.5 V13.5 A2.5 2.5 0 0 1 17.5 16 H10 L5.5 20 V16 A2.5 2.5 0 0 1 4 13.5 Z"
            fill="currentColor"
        />
        <circle cx="8.5" cy="9.5" r="1.3" fill="var(--accent)" />
        <circle cx="12" cy="9.5" r="1.3" fill="var(--accent)" />
        <circle cx="15.5" cy="9.5" r="1.3" fill="var(--accent)" />
    </svg>
}

def:pub ChatBubble -> JsxElement {
    has open: bool = False;

    <>
        {if open {
            <section style={PANEL} role="dialog" aria-label="Advisor chat">
                <header style={PANEL_HEAD}>
                    <LogoMark size={26} />
                    <div style={{"flex": "1", "minWidth": "0"}}>
                        <strong style={{"display": "block"}}>Your advisor</strong>
                        <Link to="/advisor" style={{"color": "var(--accent-text)", "fontSize": "0.85rem", "fontWeight": "600"}}>Open full page</Link>
                    </div>
                    <button
                        type="button"
                        onClick={lambda { open = False; }}
                        aria-label="Close advisor chat"
                        style={{"width": "36px", "height": "36px", "borderRadius": "999px", "border": "1px solid var(--border)", "background": "var(--surface)", "color": "var(--text)", "cursor": "pointer", "font": "inherit"}}
                    >
                        ✕
                    </button>
                </header>
                <div style={PANEL_BODY}>
                    <AdvisorChat compact={True} />
                </div>
            </section>
        }}
        <button
            type="button"
            style={BUBBLE_BUTTON}
            onClick={lambda { open = not open; }}
            aria-label={"Close advisor chat" if open else "Chat with your advisor"}
            aria-expanded={open}
        >
            {if open {
                <span style={{"fontSize": "1.4rem", "lineHeight": "1"}}>✕</span>
            } else {
                <ChatIcon />
            }}
        </button>
    </>
}
