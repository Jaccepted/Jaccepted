"""Turn the intake draft saved in this browser into a matching Profile."""

import from .matching { Profile }

def saved(data: any, key: str, fallback: str) -> str {
    value = data[key];
    if value {
        return value as str;
    }
    return fallback;
}

def:pub profile_from(data: any) -> Profile {
    return Profile(
        gpa_unweighted=saved(data, "gpa_unweighted", ""),
        gpa_scale=saved(data, "gpa_scale", "4.0"),
        test_plan=saved(data, "test_plan", "none"),
        sat_total=saved(data, "sat_total", ""),
        act_composite=saved(data, "act_composite", ""),
        undecided=saved(data, "undecided", "no"),
        major1=saved(data, "major1", ""),
        major2=saved(data, "major2", ""),
        major3=saved(data, "major3", ""),
        regions=saved(data, "regions", ""),
        location_importance=saved(data, "location_importance", "ignore"),
        setting=saved(data, "setting", ""),
        setting_importance=saved(data, "setting_importance", "ignore"),
        distance=saved(data, "distance", ""),
        distance_importance=saved(data, "distance_importance", "ignore"),
        size_small=saved(data, "size_small", "yes"),
        size_medium=saved(data, "size_medium", "yes"),
        size_large=saved(data, "size_large", "yes"),
        size_importance=saved(data, "size_importance", "ignore"),
        want_public=saved(data, "want_public", "yes"),
        want_private=saved(data, "want_private", "yes"),
        control_importance=saved(data, "control_importance", "ignore"),
        religious=saved(data, "religious", ""),
        religious_importance=saved(data, "religious_importance", "ignore"),
        want_hbcu=saved(data, "want_hbcu", "no"),
        hbcu_importance=saved(data, "hbcu_importance", "ignore"),
        want_womens=saved(data, "want_womens", "no"),
        womens_importance=saved(data, "womens_importance", "ignore"),
        max_price=saved(data, "max_price", ""),
        price_importance=saved(data, "price_importance", "ignore"),
        outcomes_importance=saved(data, "outcomes_importance", "ignore"),
        income_bracket=saved(data, "income_bracket", ""),
        home_state=saved(data, "home_state", ""),
        home_zip=saved(data, "home_zip", "")
    );
}
