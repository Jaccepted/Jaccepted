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
import from matching { CollegeDetail, CollegeMatch, MatchResult, Profile, college_detail, match_colleges, starting_list }
import from advisor { AdvisorChoice, AdvisorResult, ask_advisor, ask_advisor_live }
import from essays { EssayIdea, EssayResult, essay_ideas }

def:pub app(children: any) -> JsxElement {
    return <>{children}</>;
}
