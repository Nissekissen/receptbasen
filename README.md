# Receptbasen

A recipe manager: save recipes from around the web (or add your own), organize them
into collections, share collections with a group, and build a shopping list from
what's inside them.

## Stack

- Ruby 3.4.8, Rails 8.1
- SQLite in development/test, Postgres in production
- Hotwire (Turbo + Stimulus), Propshaft
- Solid Queue, Solid Cache, Solid Cable
- Anthropic API, for parsing scraped recipe pages and extracting tags/ingredients
- Deployed as a Docker container via [Kamal](https://kamal-deploy.org)

## Getting started

Requires Ruby 3.4.8 (see `.ruby-version`) and Bundler.

\`\`\`bash
bin/setup
\`\`\`

Installs gems, prepares the database, clears logs/tmp, and starts the dev server.
Pass `--skip-server` to do everything except start the server, `--reset` to reset
the database.

## Environment variables

- `ANTHROPIC_API_KEY` — needed for recipe parsing and tag/ingredient extraction
  (see `app/services`). Can also be set via `Rails.application.credentials.anthropic_api_key`.
  The app boots without it; features that call the Anthropic API just won't work.

## Tests and checks

\`\`\`bash
bin/ci
\`\`\`

Runs the full suite: Rubocop, `bundler-audit`, importmap vulnerability audit,
Brakeman, and the Rails test suite. To just run the tests:

\`\`\`bash
bin/rails test
\`\`\`

## Deployment

Deployed via Kamal — see `config/deploy.yml`.
