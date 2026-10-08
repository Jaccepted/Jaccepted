"""Profile intake, reached from Create account."""

import from ..frontend { IntakeForm }
import from ..theme { Shell }

def:pub Intake -> JsxPage {
    <Shell>
        <IntakeForm />
    </Shell>
}
