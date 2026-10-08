"""Start page. Title, then account actions."""

import from "@jac/runtime" { Link }
import "../styles/home.css";

def:pub Home -> JsxPage {
    <main className="home">
        <h1 className="home-title">Jaccepted</h1>
        <p className="home-tagline">A college list that starts from your profile.</p>
        <div className="home-actions">
            <Link className="home-create" to="/intake">Create account</Link>
            <button type="button" className="home-signin">Sign in</button>
        </div>
    </main>
}
