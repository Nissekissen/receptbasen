# Cook mode — implementation plan

Status: planning complete, not yet built. Written 2026-08-07 to hand off from a
planning conversation into an implementation session. See also
[roadmap-v1.md](roadmap-v1.md) for how this fits the broader v1.0.0 plan.

## Goal

Full-screen, mobile-first step-through view for use while actually cooking (phone on
the counter, hands messy). Replaces scrolling the normal recipe page during cooking.

## Screen spec

- Exit control (`×`) top-left, recipe name (truncated) top-center, wake-lock
  indicator (eye icon) top-right — the icon exists so the user can see at a glance
  that the screen won't lock, not just as decoration.
- Progress bar + "Steg X av Y" / percent, above the step content.
- Current step in large text.
- Timer chip — appears only when the step's text contains a parseable duration
  (e.g. "ca 5 minuter"). Parsing should happen server-side (a Ruby helper), not in
  JS, so it's testable.
- Next-step preview — a small, muted "Nästa: …" line, always visible under the
  timer chip, showing just the following step's text with no tap required.
  Expandable (native `<details>`, same pattern as the ingredients panel) to reveal
  2-3 steps further out, for planning parallel prep (e.g. "start the oven now").
- Ingredients panel — collapsed by default (`<details>`), showing the full
  ingredient list. Per-step ingredient tagging (showing only what's relevant to the
  current step) is a nice-to-have, deferred — see open questions.
- Bottom nav: "Föregående" (secondary style) / "Nästa steg" (primary style,
  larger — it's the button hit far more often). On the last step, "Nästa steg"
  becomes "Markera som lagad" and, instead of just advancing, submits the
  mark-as-cooked action and exits cook mode.
- Visual theme: matches the app's existing palette exactly, not a generic style —
  Fraunces (headings, unused here since there's no title-sized heading in this
  view), Karla (body/step text), IBM Plex Mono (buttons, badges, timer chip,
  uppercase micro-labels). Colors: `#33492F` accent / `#233021` accent-dark /
  `#D9E4C9` accent-light / `#252B22` ink / `#FBF7EE` background / `#8a8a86` muted
  text. Buttons use the existing 3px corner radius, badges 6px, tags 4px — all
  pulled from `app/assets/stylesheets/{application,buttons,recipe_detail}.css`,
  not invented.

## Data model decisions made along the way

- **`cook_logs`**: new table, `user_id` + `recipe_id` + `created_at`, no
  uniqueness constraint — repeat cooks are the strongest signal the app has, so the
  same user can log the same recipe any number of times. Decoupled from
  `saved_recipes`/collections entirely — logging a cook shouldn't require having
  saved the recipe. Indexes: `recipe_id` alone (aggregate "cooked N times"
  queries), and `[user_id, created_at]` (personal "what did I cook this month").
  This is also the first real prerequisite for the recommendation work discussed
  earlier — see roadmap-v1.md's "signal logging infrastructure" section.
- **Personal note**: deliberately *not* just exposing the existing
  `saved_recipes.note` column. `saved_recipes` is unique on
  `[collection_id, recipe_id]`, not `[user_id, recipe_id]` — a user can save the
  same recipe into multiple collections simultaneously (confirmed via the
  save-menu's multi-checkbox UI), which would leave ambiguous which collection's
  copy owns "the" note. A personal note is about the user's relationship with the
  *recipe*, not their filing system, so it needs its own store scoped to
  `[user_id, recipe_id]`, independent of collections — same reasoning as
  `cook_logs`. Entry point: a collapsed "+ Lägg till anteckning" affordance on the
  recipe detail page, below the description. Optional secondary entry point: a
  prompt right after finishing cook mode ("Hur gick det?"), since that's often the
  actual moment something's worth writing down.

## Wiring plan

### Routes

- A `cook` member action on `recipes` (alongside the existing `extract_tags` /
  `add_to_shopping_list` member routes).
- A `log_cook` member action (or a small `cook_logs` resource if
  index/destroy — correcting an accidental log — turns out to matter).
- A note endpoint, shaped by the model decision above — likely a singular nested
  resource off `recipes` (e.g. `resource :note, controller: "recipe_notes"`).

### Backend (Nils)

- `cook_logs` model + migration.
- The decoupled note model + migration.
- `RecipesController#cook` — mirrors `#show`'s visibility checks
  (`@recipe.visible_to?`), since cook mode needs the same "can this user see this
  recipe" gate.
- `log_cook` and note-save actions, both responding with Turbo Streams so the page
  updates without a full reload.

### Frontend (Claude)

- A chrome-free layout for cook mode — the app currently has one layout
  (`layouts/application.html.erb`) that always renders `shared/navbar`. Needs
  either a dedicated `layouts/cook_mode.html.erb`, or a body-class + CSS
  conditional. Leaning toward a dedicated layout file (one-line `layout` directive
  on the controller action, cleaner than a conditional every future layout change
  has to remember) — open decision.
- `recipes/cook.html.erb` — renders *all* steps into the DOM up front (each
  tagged with its index), not one step per request. This is what makes step
  navigation instant and lets the wake lock persist without being re-acquired on
  every tap. Same approach `recipe_flow_controller.js` already uses for the
  multi-step parsing UI.
- `cook_mode_controller.js` (Stimulus) — step targets, a current-index value,
  `next`/`previous` actions that toggle visibility and update the progress
  bar/counter, and swap the next-step preview text. Wake lock request/release in
  `connect()`/`disconnect()` — purely client-side, no backend involvement.
- A Ruby helper (e.g. `step_duration_seconds`) that parses a duration out of
  `step.content` server-side; the Stimulus controller just reads a `data-duration`
  attribute and runs a countdown.
- The note field reuses the existing `auto-submit` Stimulus controller verbatim
  (same one the save-menu checkboxes already use) — submits on blur, Turbo Stream
  swaps the "+ Lägg till anteckning" link for the saved text.
- New stylesheet for cook mode, imported via `application.css` same as the other
  page-specific stylesheets already are.
- System test covering the full flow: open recipe → enter cook mode → advance
  through steps → mark as cooked → cook count increments on the recipe page.

### Suggested build order

1. `cook_logs` model + route.
2. Note model + route.
3. View + Stimulus controller + CSS, wired against those endpoints (can start
   against stubbed responses to parallelize with step 1-2 if useful).

## Open questions carried over

1. v1.0.0 audience — small circle vs public-launch bar (affects how much this and
   other features need hardening).
2. Per-step ingredient tagging vs the static full-list fallback for v1.
3. Whether to add a "not interested" negative signal alongside `cook_logs` now or
   defer it fully to post-1.0.
4. Cook mode layout: dedicated `layouts/cook_mode.html.erb` vs conditional navbar
   hide.
