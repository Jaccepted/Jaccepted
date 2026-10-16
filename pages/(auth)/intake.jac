"""Profile intake, reached after create account or sign in."""

import from ...frontend { IntakeForm }
import from ...theme { Shell }

def:pub Intake -> JsxPage {
    <Shell>
        <IntakeForm />
    </Shell>
}
