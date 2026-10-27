"""Profile intake, reached after create account or sign in."""

import from ...frontend { IntakeForm }
import from ...theme { Shell }
import from ...components.nav { TopNav }

def:pub Intake -> JsxPage {
    <Shell>
        <TopNav current="intake" />
        <IntakeForm />
    </Shell>
}
