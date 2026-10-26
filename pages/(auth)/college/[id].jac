"""College details, reached from a college name on the results page."""

import from ....college_detail { CollegeView }
import from ....theme { Shell }

def:pub CollegePage -> JsxPage {
    <Shell>
        <CollegeView />
    </Shell>
}
