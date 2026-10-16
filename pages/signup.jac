"""Create account page."""

import from ..auth_pages { SignupForm }
import from ..theme { Shell }

def:pub Signup -> JsxPage {
    <Shell>
        <SignupForm />
    </Shell>
}
