"""A daily cap on AI requests for each signed-in student.

The advisor and essay ideas call a paid model, and sign-up is open, so without
a cap one account could loop requests and run up the bill. Each account's count
lives on its own graph root and resets at midnight UTC.
"""

import os;
import from datetime { datetime, timezone }

# JACCEPTED_AI_DAILY_LIMIT overrides the default without a code change.
glob AI_DAILY_LIMIT: int = int(os.environ.get("JACCEPTED_AI_DAILY_LIMIT", "25"));
glob LIMIT_MESSAGE: str = "You've used today's " + str(AI_DAILY_LIMIT) + " AI requests. They reset tomorrow, and Explore still works.";

node AiUsage {
    has day: str = "",
        calls: int = 0;
}

def usage -> AiUsage {
    found = [root -->][?:AiUsage];
    if found {
        return found[0];
    }
    return root ++> AiUsage();
}

def today -> str {
    return datetime.now(timezone.utc).date().isoformat();
}

"""Count one AI request for the signed-in student. False once today's cap is used up."""
def use_ai_request -> bool {
    record = usage();
    day = today();
    if record.day != day {
        record.day = day;
        record.calls = 0;
    }
    if record.calls >= AI_DAILY_LIMIT {
        return False;
    }
    record.calls = record.calls + 1;
    return True;
}
