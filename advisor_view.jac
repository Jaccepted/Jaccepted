"""The Advisor page: the full-size advisor conversation."""

import from .advisor_chat { AdvisorChat }
import from .list_store { refresh_saved }
import from .components.nav { TopNav }
import from .theme { WIDE_PAGE }

def:pub AdvisorView -> JsxElement {
    has saved_count: int = -1;

    async def load -> None {
        saved_count = len(await refresh_saved());
    }

    can with entry {
        load();
    }

    <>
        <TopNav current="advisor" saved_count={saved_count} />
        <div style={WIDE_PAGE}>
            <AdvisorChat autostart={True} onSavedCount={lambda (count: int) { saved_count = count; }} />
        </div>
    </>
}
