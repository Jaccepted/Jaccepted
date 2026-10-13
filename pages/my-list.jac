"""Saved colleges, reached from the results page."""

import from ..my_list { MyList }
import from ..theme { Shell }

def:pub SavedList -> JsxPage {
    <Shell>
        <MyList />
    </Shell>
}
