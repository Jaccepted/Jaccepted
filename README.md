# Jaccepted

Jaccepted helps high-school students decide **which colleges to apply to**. A student
enters their academic profile and preferences once. Jaccepted matches them against
public data on about 2,000 US four-year colleges and sorts the results into
**Reach / Target / Likely**, with a plain-English reason for each school.

Built as a full-stack [Jac](https://www.jaseci.org/) web app. See [SPEC.md](SPEC.md)
for the product spec and the decisions behind it.

## Features

| Page | Route | What it does |
|---|---|---|
| Home | `/` | What Jaccepted does, plus sign-in and sign-up |
| Profile | `/intake` | Step-by-step intake: academics, test scores, majors, campus and cost preferences |
| Explore | `/results` | Rule-based matches grouped by bucket, with search, sort and save/dismiss |
| College detail | `/college/:id` | Admissions, cost and outcomes data, plus how the student compares |
| Advisor | `/advisor` | AI agent that builds or refines a list from a plain-English request |
| My Colleges | `/my-list` | Application tracker (status, plan, deadline, checklist, notes) and AI essay ideas |

Signed-out visitors keep their data in the browser. Signed-in students' data is
saved to their account.

## Getting started

### Requirements

- **Jac**, at exactly the version pinned in `jac.toml` (`jac-version = "==0.37.21"`).
  > **TODO:** add the exact install command for this version. 0.37.21 isn't the
  > public `jaclang` release on PyPI (which is 0.16.x), so it's installed from
  > another source.
- **Node.js**, which installs and builds the React front end listed under
  `[dependencies.npm]` in `jac.toml`.
- An **Anthropic API key**, needed only for the AI advisor and essay ideas. Everything
  else works without it.

### Environment variables

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `ANTHROPIC_API_KEY` | For AI features | — | Key for the advisor and essay ideas. Never commit it. |
| `JACCEPTED_MODEL` | No | `anthropic/claude-opus-5-5` | Model used by the AI features |
| `JACCEPTED_AI_DAILY_LIMIT` | No | `25` | AI requests allowed per account per day (once the daily-limit PR is merged) |

Put local settings in `jac.local.toml` or your shell. Both `jac.local.toml` and `.venv/` are gitignored.

### Run the app

```bash
export ANTHROPIC_API_KEY=sk-ant-...   # optional; only needed for AI features
jac run --dev main.jac
```

Then open http://localhost:8000. Dev mode hot-reloads client files. After changing
server code, restart the server.

### Check and test

```bash
jac check main.jac           # type-check and lint
jac test matching.test.jac   # or any *.test.jac file
```

| Test file | Covers |
|---|---|
| `matching.test.jac` | Buckets, fit score, filters, sorting, search, net price, college detail, speed (< 2 s) |
| `advisor.test.jac` | Advisor tools, grounding (invented picks dropped), failure handling |
| `essays.test.jac` | Essay ideas: drafted text is dropped, the rules are sent, failure handling |
| `intake_rules.test.jac` | Intake form validation |

The AI tests use ByLLM's `MockLLM`, so **they need no API key and cost nothing**.

## Project layout

```
main.jac              App entry; registers the server endpoints
matching.jac          Matching engine: filters → Reach/Target/Likely → 0–100 fit score
advisor.jac           AI advisor agent (ByLLM) and its tools; picks are grounded in matching
advisor_chat.jac      Advisor conversation UI (shared by /advisor and the chat bubble)
essays.jac            AI essay-angle brainstorming; never writes essay text
accounts.jac          Per-account storage (profile, saved list, dismissed) on the user's graph root
list_store.jac        Browser storage for the saved list, synced to the account when signed in
frontend.jac          Profile intake wizard
intake_rules.jac      Intake validation
profile_data.jac      Turns the saved intake draft into a matching Profile
results.jac           Explore page
college_detail.jac    College detail page
my_list.jac           My Colleges tracker and essay ideas UI
majors.jac            Suggested majors mapped to CIP program codes
theme.jac             Shared styles, plus light and dark themes
components/           Nav, chat bubble, form fields, logo, spinner, theme toggle
pages/                File-based routes; pages under (auth)/ require sign-in
scripts/pull_colleges.jac   Rebuilds the data/ tables from public sources
data/                 College, program, Common Data Set and ZIP tables used at runtime
```

## Data

The matching tables in `data/` are committed, so the app runs without downloading
anything. `data/manifest.json` lists the counts and exact source releases:

- **IPEDS** (U.S. Department of Education): directory, admissions, enrollment, tuition, net price by income, graduation rates and programs
- **College Scorecard**: earnings and outcomes, plus earnings by field of study
- **Common Data Set**, via the collegedata.fyi API: GPA averages, SAT/ACT composites, ED/EA, and in-state vs. out-of-state rates (about 500 schools)
- **Census ZCTA gazetteer**: ZIP-code centroids for distance
- **Women's College Coalition** member list

To refresh the data, run this from the repo root. Raw downloads go to `data/raw/`,
which is gitignored.

```bash
jac run scripts/pull_colleges.jac
```

## AI guardrails

The advisor and essay ideas follow the rules in SPEC.md §6.6:

- No admission odds or guarantees. Buckets are always labeled as estimates.
- Every fact and number comes from our data through tools. Picks that aren't real matches for the student are dropped on the server.
- The model never receives the student's email, name, ZIP code or income bracket.
- Essay ideas suggest angles only. Anything that reads like drafted essay text is removed before it reaches the page.
- AI features are for signed-in students only.

## Contributing

- Branch from `main`, then open a pull request. Keep each PR to one change.
- Run `jac check` and the relevant `jac test` files before pushing.
- Jac syntax is easy to confuse with Python or JSX. [AGENTS.md](AGENTS.md) explains how to use
  `jac guide` to look up the current syntax.
