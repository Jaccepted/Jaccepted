"""Jaccepted.

Pages live under pages/. This entry renders the router and registers the
matching endpoint.
"""

import from matching { CollegeMatch, MatchResult, Profile, match_colleges }

def:pub app(children: any) -> JsxElement {
    return <>{children}</>;
}
