"""Gray placeholders shown while the results and college pages load.

They are hidden from screen readers (the pages already announce "Loading…"),
and they stop shimmering for students who ask their device to reduce motion.
The shimmer and that rule live in THEME_CSS, keyed on [data-skeleton].
"""

import from ..theme { CARD, DETAIL_GRID, STACK }

def:pub SkeletonLine(width: str = "100%", height: str = "1rem") -> JsxElement {
    <div data-skeleton="true" style={{"width": width, "height": height}}></div>
}

def ResultRowSkeleton -> JsxElement {
    <div style={{"display": "flex", "flexDirection": "column", "gap": "0.5rem", "padding": "0.85rem 0", "borderTop": "1px solid var(--border)"}}>
        <SkeletonLine width="55%" height="1.1rem" />
        <SkeletonLine width="80%" />
        <SkeletonLine width="70%" />
    </div>
}

def BucketSkeleton -> JsxElement {
    <section style={CARD}>
        <SkeletonLine width="30%" height="1.6rem" />
        <div style={{"height": "0.6rem"}}></div>
        <SkeletonLine width="85%" />
        <div style={{"height": "0.6rem"}}></div>
        <ResultRowSkeleton />
        <ResultRowSkeleton />
        <ResultRowSkeleton />
    </section>
}

"""Stand-in for the Reach, Target and Likely cards on the Explore page."""
def:pub ResultsSkeleton -> JsxElement {
    <div style={STACK} aria-hidden="true">
        <BucketSkeleton />
        <BucketSkeleton />
        <BucketSkeleton />
    </div>
}

def PanelSkeleton -> JsxElement {
    <section style={CARD}>
        <SkeletonLine width="45%" height="1.4rem" />
        <div style={{"height": "0.8rem"}}></div>
        <div style={{"display": "flex", "flexDirection": "column", "gap": "0.7rem"}}>
            <SkeletonLine />
            <SkeletonLine width="92%" />
            <SkeletonLine width="85%" />
            <SkeletonLine width="90%" />
        </div>
    </section>
}

"""Stand-in for the header and the stat panels on the college page."""
def:pub DetailSkeleton -> JsxElement {
    <div style={STACK} aria-hidden="true">
        <SkeletonLine width="8rem" height="0.9rem" />
        <SkeletonLine width="60%" height="2.2rem" />
        <SkeletonLine width="35%" />
        <div style={DETAIL_GRID}>
            <PanelSkeleton />
            <PanelSkeleton />
            <PanelSkeleton />
            <PanelSkeleton />
        </div>
    </div>
}
