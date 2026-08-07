# Receptbasen — roadmap to v1.0.0

Status: draft, last discussed 2026-08-07. This is a living plan, not a spec — revisit as
things ship or priorities shift.

## What v1.0.0 means

Working definition: **the core loop is complete and trustworthy**, not "feature-rich."
A user can save, organize, cook, and share recipes without hitting a dead end, and the
app is capturing the data it'll need for smarter features later. It is *not* a public
launch bar (no moderation tooling, no scale-tested infra) unless we decide otherwise.

Open question to resolve before final scoping: is v1.0.0 aimed at a small circle of
users (current state) or a public-launch quality bar? That changes how much weight
items like comment moderation and data export deserve. Assuming small-circle for the
plan below; flag if that's wrong.

## Foundation already in place

Worth stating explicitly, because it changes scope on several items below:

- `saved_recipes` already has `note` and `rating` columns — unused in any controller or
  view. Personal notes and ratings are a UI task, not a data-model task.
- "Friends" already exists as `Group` — `public`/`private` visibility, `Membership`,
  token-based `Invite`, and `Collection` can belong to a group. No new social model
  needed, just better framing.
- `Recipe` distinguishes scraped (`owner_id` nil) from manual (owned) recipes — matters
  for anything social/comments, since most recipes have no real "owner."
- `Tag` has a `category`, giving a filter dimension for search/explore without new
  schema.
- `config/recurring.yml` already provides scheduled-job infra (Solid Queue) — the
  natural home for any future data-retention/pruning job.

## Phasing

### Phase 1 — quick wins (ship anytime, don't need to wait for 1.0.0)

- **Personal notes on saved recipes** — expose the existing `saved_recipes.note` field
  in the UI. Almost no backend work.
- **Ratings UI** — expose the existing `saved_recipes.rating` field.
- **Cook mode** — see spec below.
- **Servings scaling** — recalculate ingredient quantities. Feasible now that
  ingredients are split into amount/unit/content.

### Phase 2 — v1.0.0 bar

- **Explore page** — heuristic-driven (tag filters, newest, most-saved, trending this
  week), *not* a real recommender. See "Recommendation prerequisites" below for why.
- **Signal logging** — `cook_logs` table plus reading existing tables as signal. See
  spec below. This is infrastructure, not a user-facing feature, but it's what makes
  Phase 3's recommendation work possible later.
- **Lightweight sharing** — reframe `Group`/`profile` so a user's public collections
  show on their profile page, without necessarily needing the heavier "group" concept
  for a casual two-person share.
- **Full-text / tag search** — prerequisite for explore being useful once the recipe
  database grows.
- **Data export** — download your recipes/collections. Cheap, builds trust, good
  checkbox for calling something 1.0.

### Phase 3 — post-1.0

- **Real recommendation engine** — once there's both a bigger recipe database and
  enough logged signal (cooks, saves, ratings) to train on.
- **Group-scoped comments** — comments visible only to members of a group/collection,
  not globally public. Lower moderation risk than open comments, reuses existing group
  infra.
- **Meal planner** — ties into the existing shopping list.
- **Public comments** — only if/when user base and moderation capacity justify it. See
  critique below.
- **Negative signal ("not interested")** — cheap addition once `cook_logs` exists,
  same shape.
- **View/impression tracking** — deliberately deferred; see reasoning below.

## Feature specs

### Cook mode

Full-screen, mobile-first step view for use while actually cooking (phone on the
counter, hands messy). Key elements from the sketch:

- Progress bar + "step X of Y" at the top — answers "where am I" without scrolling.
- A visible wake-lock indicator, since the whole point breaks if the screen locks
  mid-step.
- Current step in large text, centered.
- A timer chip that appears only when the step's text contains a parseable duration
  (e.g. "ca 5 minuter") — cheap regex against `steps.content`, no schema change.
- Ingredients collapsed by default, expandable per step.
- Large, uneven prev/next buttons — "next" is hit far more often, so it's bigger and
  thumb-anchored.
- The last step's "next" action becomes "mark as cooked," which both exits cook mode
  and writes a `cook_logs` row (see below) — zero extra taps for the highest-value
  signal in the app.

**Open scoping question:** per-step ingredient tagging (which ingredients belong to
which step) is a bigger lift — needs a join between ingredients and steps. Static
"show the full ingredient list in a collapsible panel" is a reasonable v1 fallback if
per-step tagging is too much upfront work.

### Signal logging infrastructure

Prerequisite work for Phase 3's recommendation engine, and for phase 2's "trending"
sort on the explore page.

**Already-free signals** — no new tables needed, just start reading them:
- `saved_recipes` — existence of a row (with `created_at`) is a save event.
- `saved_recipes.rating` — explicit signal, currently unused.
- `shopping_list_items` — a weaker intent signal (added ingredients to shopping list).

**New: `cook_logs`.** Append-only event log, not a toggle — a user might cook the same
recipe dozens of times, and that repetition is itself valuable signal (arguably a
better "this recipe is good" indicator than a star rating). Columns: `user_id`,
`recipe_id`, `created_at`. No uniqueness constraint — repeat cooks must be allowed.
Indexes: `recipe_id` alone (aggregate queries — "cooked N times by M people"), and a
composite on `[user_id, created_at]` (personal history — "what did I cook this
month"). Decoupled from `saved_recipes`/collections — cooking shouldn't require having
saved the recipe first. Personal history is private to the user by default; aggregate
counts can be public/group-visible since a count carries no attribution.

**Architecture decision: dedicated tables per signal type, not one generic `events`
table.** A single polymorphic events table (`event_type` + metadata blob) avoids
future migrations, but fights the actual requirements here: different signals need
different constraints (a rating wants a 1–5 check, a cook log wants none), different
retention policies (keep cook events forever, but maybe expire raw view events after a
few months), and wildly different volume profiles. Splitting by type costs a migration
per new signal type, which is cheap at this scale. This also matches the existing
codebase pattern (`saved_recipes`, `shopping_list_items` are already separate,
purpose-built tables).

**Deliberately deferred: view/impression tracking.** Highest row volume, weakest
per-row signal, and needs a retention/pruning story from day one or it becomes
unmanageable. Hold off until actually building the recommender and it's clear it's
needed (e.g. as a denominator for save-rate, or as implicit negative signal). When it
does happen, `config/recurring.yml` already provides the scheduling infra for a prune
job.

**When the recommender is actually built:** write one read-side query/service that
pulls a feature set from `saved_recipes`, `shopping_list_items`, and `cook_logs`
together. Don't build that unifying abstraction now — there's no recommender yet to
tell us what shape it needs, and guessing is the premature part.

### Comments & notes (reshaped from the original idea)

- **Personal notes**: Phase 1, ship almost immediately.
- **Public comments**: not recommended for v1.0.0. Most recipes have no real "owner"
  (scraped, `owner_id` nil), so a public comment thread under someone else's scraped
  content is moderation/spam exposure with little payoff at current traffic.
- **Group-scoped comments** (Phase 3): a safer middle ground — comments visible only
  to members of the group/collection a recipe is shared in. Reuses existing group
  infra, no new moderation surface against the open internet.

### Friends / social (reshaped from the original idea)

Don't build a parallel "friends" system — `Group` already provides
public/private visibility, membership, and invite tokens. The gap is UX framing, not
data model: surface a user's public collections on their `profile` page (route already
exists), and consider whether "group" is the right word in the UI for a lightweight
two-person share versus a real invite-based group.

### Recommendation prerequisites (why it's Phase 3, not Phase 2)

Two things need to exist before a real recommendation algorithm is worth building: a
bigger recipe database, and actual behavioral signal to train on (which barely exists
today — `rating` unused, no cook history). Phase 2 ships the heuristic explore page
(tag filters, newest, most-saved) as a stopgap that's useful immediately and doubles as
the thing generating the training data — signal has to accumulate before the "real"
version can beat a simple heuristic anyway.

## Explicitly out of scope for v1.0.0

- ML/statistical recommendation engine
- Public, globally-visible comments
- View/impression logging
- Per-step ingredient tagging (unless scoped in during cook mode build)

## Open questions

1. Is v1.0.0 a bar for a small-circle tool or public-launch readiness? Changes the
   weight of moderation and export work.
2. Cook mode: full per-step ingredient tagging, or static full-list panel for v1?
3. Ship a "not interested" negative signal alongside `cook_logs` in Phase 2, or push
   it fully to Phase 3?
