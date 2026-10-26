"""Jaccepted.

Pages live under pages/. This entry renders the router and registers the
matching endpoint.
"""

import from accounts {
    load_dismissed_ids,
    load_intake,
    load_list,
    save_dismissed,
    save_intake,
    save_list
}
import from matching { CollegeDetail, CollegeMatch, MatchResult, Profile, college_detail, match_colleges }

def:pub app(children: any) -> JsxElement {
    return <>{children}</>;
}
