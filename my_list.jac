"""My List: saved colleges by bucket, with a balance check."""

import from .list_store { balance_warning, load_saved, store_saved }
import from .components.nav { TopNav }
import from .theme {
    BANNER,
    BUCKET_HEAD,
    CARD,
    EYEBROW,
    FACTS,
    FIT,
    HINT,
    LEDE,
    NAV,
    PAGE,
    RESULT,
    RESULT_HEAD,
    RESULT_NAME,
    SECONDARY,
    STACK,
    SUCCESS,
    TITLE,
    bucket_look
}

glob BUCKETS: list[list[str]] = [["reach", "Reach"], ["target", "Target"], ["likely", "Likely"]];

def:pub MyList -> JsxElement {
    has items: list[dict[str, any]] = [];

    can with entry {
        items = load_saved();
    }

    def remove(unitid: str) -> None {
        items = [item for item in items if item["unitid"] != unitid];
        store_saved(items);
    }

    warning = balance_warning(items);
    reach = len([item for item in items if item["bucket"] == "reach"]);
    target = len([item for item in items if item["bucket"] == "target"]);
    likely = len([item for item in items if item["bucket"] == "likely"]);

    <>
        <TopNav current="my-list" saved_count={len(items)} />
        <div style={PAGE}>
            <header>
                <p style={EYEBROW}>My List</p>
                <h1 style={TITLE}>Jaccepted</h1>
                <p style={LEDE}>The colleges you saved, grouped by bucket. Saved in this browser.</p>
            </header>
            <main style={STACK}>
                {if len(items) == 0 {
                    <p style={HINT}>Nothing saved yet. Use "Save to My List" on your results.</p>
                } else {
                    <p style={SUCCESS if not warning else BANNER} role="status">
                        {warning if warning else str(reach) + " reach, " + str(target) + " target, " + str(likely) + " likely. A balanced list."}
                    </p>
                }}
                {for bucket in BUCKETS {
                    <section key={bucket[0]} style={CARD} aria-labelledby={"saved-" + bucket[0]}>
                        <div style={BUCKET_HEAD}>
                            <h2 id={"saved-" + bucket[0]} style={bucket_look(bucket[0])}>{bucket[1]}</h2>
                            <span style={HINT}>{str(len([item for item in items if item["bucket"] == bucket[0]])) + " saved"}</span>
                        </div>
                        <ul style={{"listStyle": "none", "margin": "0.6rem 0 0", "padding": "0"}}>
                            {for item in [item for item in items if item["bucket"] == bucket[0]] {
                                <li key={item["unitid"]} style={RESULT}>
                                    <div style={RESULT_HEAD}>
                                        <div>
                                            <h3 style={RESULT_NAME}>{item["name"]}</h3>
                                            <p style={FACTS}>{item["city"] + ", " + item["state"]}</p>
                                        </div>
                                        <div style={FIT} aria-label={"Fit " + str(item["fit"]) + " out of 100"}>{item["fit"]}</div>
                                    </div>
                                    <div style={NAV}>
                                        <button type="button" style={SECONDARY} onClick={lambda { remove(item["unitid"] as str); }}>Remove</button>
                                    </div>
                                </li>
                            }}
                        </ul>
                    </section>
                }}
            </main>
        </div>
    </>
}
