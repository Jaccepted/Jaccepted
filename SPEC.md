# Jaccepted — Product Spec

> Status: **Draft v0.1** · Last updated 2026-10-01
> Sections marked **[DECISION]** are open questions to settle before building.

## 1. Summary

Jaccepted helps high-school students figure out **which colleges to apply to**.
A student enters their academic profile and preferences, and Jaccepted returns a
ranked, explained list of colleges, sorted into **Reach / Target / Likely**
buckets, that they can save, compare and refine into a final application list.

## 2. Problem

- Students build college lists from rankings, word of mouth and guesswork. Lists
  end up top-heavy (all reaches) or ignore fit (cost, size, location, major).
- Counselors are overloaded. The national average is roughly 1 counselor per
  400 students.
- The data exists (admit rates, test ranges, net cost, programs), but it's
  spread across sites and hard to compare against your own profile.

## 3. Goals and non-goals

**Goals**
1. Turn a student's profile into a balanced, personalized college list in under 10 minutes.
2. Explain *why* each college was suggested and how competitive the student is there.
3. Let students tweak preferences and immediately see the list change.

**Non-goals (for v1)**
- Predicting admission with a precise probability. We give buckets, not percentages.
- Writing essays or filling in applications.
- Covering international (non-US) universities.
- Scholarship search and financial-aid application help.

## 4. Users

| Persona | Description | Primary need |
|---|---|---|
| **Student** (primary) | 10th–12th grader starting a college search | "Where should I apply, and where do I have a real shot?" |
| Parent | Helps the student, worried about cost | "What will these schools actually cost us?" |
| Counselor (later) | Supports many students | "Give me a sane starting list for each student." |

## 5. User flow

```
Sign up / start as guest
  → Profile intake (academics, activities, preferences)
  → Matching runs
  → Results: ranked list grouped Reach / Target / Likely
      → College detail (stats, fit breakdown, "why this school")
      → Save to My List / dismiss
      → Adjust preferences → re-run
  → My List: balance check (e.g. "you have 7 reaches and 1 likely")
```

## 6. Functional requirements

### 6.1 Profile intake

The student enters everything once and can edit it at any time. Every field is
optional unless marked required. More data gives better matches.

**Academics**
- GPA, unweighted (required) and weighted, with the scale (4.0, 5.0, 100)
- Class rank / percentile (optional)
- Course rigor: number of AP/IB/honors/dual-enrollment courses
- Test scores: SAT (total + sections), ACT (composite + sections), or "not submitting"
- Graduation year (required)

**Activities and achievements**
- Up to 10 activities: name, category, role, years, hours/week, a short description
- Awards: name and level (school / regional / state / national / international)

**Intended study**
- Up to 3 intended majors or areas, or "undecided"

**Preferences** (each with an importance weight: *must have / nice to have / don't care*)
- Location: states/regions, distance from home, urban / suburban / rural
- Size: small (<5k), medium (5–15k), large (>15k)
- Type: public / private, religious affiliation, HBCU, women's college
- Cost: max annual net price the family can afford, plus household income bracket (for net-price estimates)
- Campus: Greek life, D1 athletics, etc. (later)

**Demographics (optional, clearly explained)**
- Home state (needed for in-state tuition and public-school admit rates)
- First-generation status
- *[DECISION]* Whether to collect any other demographic fields at all

### 6.2 College data

- Source: the **U.S. Department of Education College Scorecard API** (free,
  public), plus IPEDS where needed. Fields used: admit rate, SAT/ACT 25th–75th
  percentiles, enrollment, location, urbanicity, control (public/private),
  average net price by income bracket, graduation rate, programs offered (CIP
  codes), median earnings.
- Scope for v1: 4-year, degree-granting US institutions with published admissions data (~2,000 schools).
- Refresh: a pull script run on a schedule (Scorecard updates yearly), cached locally.
- *[DECISION]* Supplement with Common Data Set data (GPA distributions, test-optional policies, ED/EA admit rates)? CDS is more detailed but has to be collected school by school.

### 6.3 Matching engine

Matching has three stages:

**Stage 1: Hard filters.** Drop any college that fails a *must-have* preference
(wrong state, over budget, doesn't offer the intended major, and so on).

**Stage 2: Competitiveness → bucket.** Estimate where the student falls in each
college's admitted-student distribution:
- Compare SAT/ACT against the school's 25th/75th percentiles. If the student isn't submitting scores, use GPA and rigor.
- Combine that with the school's admit rate:

| Bucket | Rule of thumb (initial heuristic, to be tuned) |
|---|---|
| **Reach** | Admit rate < 15% (for everyone), **or** student below the school's 25th percentile |
| **Target** | Student within the 25th–75th percentile and admit rate ≥ 15% |
| **Likely** | Student above the 75th percentile and admit rate ≥ 50% |

Any school with an admit rate under 15% is always a Reach, whatever the scores.

**Stage 3: Fit score (0–100).** A weighted sum of how well each school matches
the *nice-to-have* preferences: major availability, size, setting, location,
affordability, and outcomes (grad rate, earnings). The student's importance
settings determine the weights.

**Output:** the list sorted by fit score within each bucket, with a suggested
balanced shortlist (default: 3 Reach / 4 Target / 3 Likely).

**Explainability:** every result shows a breakdown, for example "Target: your
SAT 1420 is within their middle 50% (1330–1480). Strong fit: offers Computer
Science, medium size, ~$18k net price for your income bracket."

*[DECISION]* Use an LLM (via Jac's `by llm`) to write the plain-English "why
this school" summary from the structured breakdown? It adds polish, but costs
money and means sending profile data to a model provider.

### 6.4 Results and My List

- Results view grouped by bucket, with filter and sort controls
- College detail page: key stats, the student's position on the score range, and the fit breakdown
- Save to / remove from My List; dismiss with "not interested" (tells future matching)
- Side-by-side comparison of 2–4 schools
- A balance indicator on My List that warns when the list is too reach-heavy or has no likely schools

### 6.5 Accounts

- Email sign-up so profile and list persist. Guest mode is optional: data is kept in the browser and can be converted to an account.
- *[DECISION]* Is guest mode in scope for the MVP?

## 7. Non-functional requirements

- **Privacy:** most users are minors, so collect the minimum. No selling or sharing of data. Optional fields are clearly marked. Users can delete their account and data.
- **Honesty:** results are always labeled as estimates. Never imply guaranteed admission.
- **Performance:** matching across ~2,000 schools returns in < 2 s.
- **Accessibility:** WCAG 2.1 AA, and mobile-friendly (students mostly use phones).

## 8. Architecture (proposed)

- **Language/runtime:** Jac (currently pinned to `jac ==0.37.21` in `jac.toml`).
- **Form:** the repo is scaffolded as a CLI (`kind = "cli"`). Proposal: build the
  matching engine as a CLI first so it's testable, then add a web front end
  (Jac full-stack / `jac-client`).
  *[DECISION]* CLI-first, or go straight to a web app?
- **Data model:** use Jac's graph (Object-Spatial Programming):
  - Nodes: `Student`, `Profile`, `Activity`, `Preference`, `College`, `Program`
  - Edges: `Student -[has]-> Profile`, `College -[offers]-> Program`, `Student -[saved {bucket, fit}]-> College`, `Student -[dismissed]-> College`
  - Walkers: `MatchColleges` (traverses `College` nodes, applies filters, scores and buckets), `BuildShortlist`
- **Data ingestion:** a `scripts/` job that pulls College Scorecard and loads `College` nodes.

## 9. MVP scope (v0.1)

| In | Out (later) |
|---|---|
| Profile intake: academics, majors, core preferences | Activities/awards affecting the match |
| Scorecard data for ~2,000 US 4-year schools | CDS / test-optional / ED-EA data |
| Hard filters + bucket heuristic + fit score | ML-based admission model |
| Results grouped by bucket, with explanations | LLM-written summaries |
| Save / dismiss / My List with balance check | Comparison view, counselor accounts |

## 10. Success metrics

- Share of users who finish intake and see results (target > 70%)
- Share of users who save ≥ 5 colleges
- List balance: share of saved lists that include at least one Likely school
- Qualitative check: a counselor reviews 20 generated lists and rates them reasonable

## 11. Open questions

1. CLI-first or web-first? (§8)
2. Is guest mode in scope for the MVP? (§6.5)
3. Should the LLM write "why this school" summaries? (§6.3)
4. Should activities/awards influence matching? They're hard to score fairly. One option is to use them only as a small boost at highly selective schools.
5. Should we add Common Data Set data, and how would we collect it? (§6.2)
6. Which demographic fields, if any, should we collect? (§6.1)
7. Repo: should this stay connected to `Jaccepted/Jaccepted` on GitHub, or move to a new remote?
