"""AI advisor, reached from the top navigation."""

import from ...advisor_view { AdvisorView }
import from ...theme { Shell }

def:pub Advisor -> JsxPage {
    <Shell>
        <AdvisorView />
    </Shell>
}
