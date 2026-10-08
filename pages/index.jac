"""Start page. Title, then account actions."""

import from "@jac/runtime" { Link }
import from ..theme { HOME, HOME_ACTIONS, HOME_CREATE, HOME_SIGNIN, HOME_TAGLINE, HOME_TITLE, Shell }

def:pub Home -> JsxPage {
    <Shell>
        <main style={HOME}>
            <h1 style={HOME_TITLE}>Jaccepted</h1>
            <p style={HOME_TAGLINE}>A college list that starts from your profile.</p>
            <div style={HOME_ACTIONS}>
                <Link style={HOME_CREATE} to="/intake">Create account</Link>
                <button type="button" style={HOME_SIGNIN}>Sign in</button>
            </div>
        </main>
    </Shell>
}
