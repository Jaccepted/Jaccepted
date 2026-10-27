"""Jaccepted logo: a shield holding a college building, with an "accepted" check badge."""

glob:pub BRAND_GREEN: str = "#0f5c4c";
glob:pub BADGE_GREEN: str = "#3fa37c";

# The same mark as an SVG string, for the browser-tab icon.
glob:pub FAVICON_SVG: str = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><path d='M24 3 L41 8.5 V22 C41 33.5 33.5 41.5 24 45 C14.5 41.5 7 33.5 7 22 V8.5 Z' fill='#0f5c4c'/><path d='M12.5 17.5 L24 11 L35.5 17.5 Z' fill='#fff'/><rect x='13' y='18.6' width='22' height='2.4' fill='#fff'/><rect x='15' y='22.2' width='3.2' height='9.8' fill='#fff'/><rect x='22.4' y='22.2' width='3.2' height='9.8' fill='#fff'/><rect x='29.8' y='22.2' width='3.2' height='9.8' fill='#fff'/><rect x='12' y='33.2' width='24' height='2.6' fill='#fff'/><circle cx='35.5' cy='35' r='7.5' fill='#3fa37c' stroke='#fff' stroke-width='2'/><path d='M31.8 35.2 L34.6 38 L39.4 32.4' fill='none' stroke='#fff' stroke-width='2.2' stroke-linecap='round' stroke-linejoin='round'/></svg>";

def:pub LogoMark(size: int = 32) -> JsxElement {
    <svg width={size} height={size} viewBox="0 0 48 48" role="img" aria-label="Jaccepted">
        <path d="M24 3 L41 8.5 V22 C41 33.5 33.5 41.5 24 45 C14.5 41.5 7 33.5 7 22 V8.5 Z" fill={BRAND_GREEN} />
        <path d="M12.5 17.5 L24 11 L35.5 17.5 Z" fill="#ffffff" />
        <rect x="13" y="18.6" width="22" height="2.4" rx="0.6" fill="#ffffff" />
        <rect x="15" y="22.2" width="3.2" height="9.8" rx="0.6" fill="#ffffff" />
        <rect x="22.4" y="22.2" width="3.2" height="9.8" rx="0.6" fill="#ffffff" />
        <rect x="29.8" y="22.2" width="3.2" height="9.8" rx="0.6" fill="#ffffff" />
        <rect x="12" y="33.2" width="24" height="2.6" rx="0.6" fill="#ffffff" />
        <circle cx="35.5" cy="35" r="7.5" fill={BADGE_GREEN} stroke="#ffffff" strokeWidth="2" />
        <path
            d="M31.8 35.2 L34.6 38 L39.4 32.4"
            fill="none"
            stroke="#ffffff"
            strokeWidth="2.2"
            strokeLinecap="round"
            strokeLinejoin="round"
        />
    </svg>
}

def:pub Logo(size: int = 32) -> JsxElement {
    <span style={{"display": "inline-flex", "alignItems": "center", "gap": "0.5rem"}}>
        <LogoMark size={size} />
        <span style={{"fontSize": str(round(size * 0.66)) + "px", "fontWeight": "700", "letterSpacing": "-0.02em", "color": "#1c2530"}}>
            <span style={{"color": BRAND_GREEN}}>Jac</span>cepted
        </span>
    </span>
}
