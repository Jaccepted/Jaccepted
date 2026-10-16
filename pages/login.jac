"""Sign in page."""

import from ..auth_pages { LoginForm }
import from ..theme { Shell }

def:pub Login -> JsxPage {
    <Shell>
        <LoginForm />
    </Shell>
}
