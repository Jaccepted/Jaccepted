"""College list results, reached after submitting the intake profile."""

import from ..results { ResultsView }
import from ..theme { Shell }

def:pub Results -> JsxPage {
    <Shell>
        <ResultsView />
    </Shell>
}
