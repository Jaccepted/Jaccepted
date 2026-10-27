"""A spinning ring shown while something is loading."""

def:pub Spinner(size: int = 20, label: str = "Loading") -> JsxElement {
    <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        role="img"
        aria-label={label}
        style={{"animation": "jac-spin 0.8s linear infinite", "flexShrink": "0"}}
    >
        <circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" strokeOpacity="0.2" strokeWidth="3" />
        <path d="M21 12 A9 9 0 0 0 12 3" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" />
    </svg>
}
