"""Display formatters shared by the results and college detail pages."""

def:pub fmt_int(n: int) -> str {
    # f"{n:,}" is not applied by the client compiler, so group digits by hand.
    text = str(int(n));
    out = "";
    count = 0;
    i = len(text) - 1;
    while i >= 0 {
        if count > 0 and count % 3 == 0 {
            out = "," + out;
        }
        out = text[i] + out;
        count = count + 1;
        i = i - 1;
    }
    return out;
}

def:pub fmt_rate(rate: float | None) -> str {
    if rate is None {
        return "—";
    }
    return str(round(float(rate) * 100.0)) + "%";
}

def:pub fmt_price(price: int | None) -> str {
    if price is None {
        return "—";
    }
    return "$" + fmt_int(price);
}

def:pub fmt_num(n: int | None) -> str {
    if n is None {
        return "—";
    }
    return fmt_int(n);
}

def:pub fmt_sat(p25: int | None, p75: int | None) -> str {
    if p25 is None {
        return "";
    }
    if p75 is None {
        return str(p25);
    }
    return fmt_int(p25) + "–" + fmt_int(p75);
}

def:pub fmt_act(p25: int | None, p75: int | None) -> str {
    if p25 is None {
        return "";
    }
    if p75 is None {
        return str(p25);
    }
    return f"{p25}–{p75}";
}
