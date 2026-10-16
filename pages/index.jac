"""Start page. Title, then account actions."""

import from "@jac/runtime" { Link, jacIsLoggedIn, jacLogout, useNavigate }
import from ..theme { HOME, HOME_ACTIONS, HOME_CREATE, HOME_SIGNIN, HOME_TAGLINE, HOME_TITLE, Shell }

def:pub Home -> JsxPage {
    has signed_in: bool = False;

    navigate = useNavigate();

    can with entry {
        signed_in = jacIsLoggedIn();
    }

    def sign_out -> None {
        jacLogout();
        signed_in = False;
        navigate("/");
    }

    <Shell>
        <main style={HOME}>
            <h1 style={HOME_TITLE}>Jaccepted</h1>
            <p style={HOME_TAGLINE}>A college list that starts from your profile.</p>
            <div style={HOME_ACTIONS}>
                {if signed_in {
                    <>
                        <Link style={HOME_CREATE} to="/intake">Continue profile</Link>
                        <Link style={HOME_SIGNIN} to="/results">View results</Link>
                        <Link style={HOME_SIGNIN} to="/my-list">My List</Link>
                        <button type="button" style={HOME_SIGNIN} onClick={sign_out}>Sign out</button>
                    </>
                } else {
                    <>
                        <Link style={HOME_CREATE} to="/signup">Create account</Link>
                        <Link style={HOME_SIGNIN} to="/login">Sign in</Link>
                    </>
                }}
            </div>
        </main>
    </Shell>
}
