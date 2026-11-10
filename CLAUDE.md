# Repository Guidelines

`dkey-client` (module `Dkey`, `require 'dkey'`) is a host-agnostic Ruby client for the Telkey dKey API, extracted
from Guestit's app and published on RubyGems. It has no Rails dependency; the host injects the account credentials,
the unit id and the auth-token store via `Dkey.configure`. README is the public guide and holds the release steps.

## Project Structure

- `lib/dkey.rb` — entry point: requires, and the `Dkey.configure`/`Dkey.config` accessors.
- `lib/dkey/client.rb` — the module-level wire API: `Dkey.connection`, `Dkey.request`, the retry policy, the
  `X-User-Id`/`X-Auth-Token` auth headers and the `ApiError` wrap.
- `lib/dkey/config.rb` — injected `client_id`, `secret`, `unit_id`, `base_url`, `timeout` and `token_store`.
- `lib/dkey/memory_token_store.rb` — the default per-process auth-token store.
- `lib/dkey/operation.rb` — the monadic base (`#call` returns a Result, `#call!` unwraps/raises).
- `lib/dkey/<resource>/<action>.rb` — one operation per file, namespaced `Dkey::<Resource>::<Action>`.
- `spec/` — RSpec + VCR; cassettes in `spec/fixtures/cassettes`.

## Boundary

- Domain mapping and persistence stay in the host: it translates grants and locks onto its own models, which is
  host vocabulary. The gem speaks wire vocabulary plus its own normalized constants (`Dkey::AccessGrants::KIND_*`).
- Credentials stay in the host: the client id, the secret and the unit id are injected or read from the host's own
  store. The auth-token store is injected too — the gem ships only the in-memory default.
- Error reporting stays in the host: an operation returns `Failure(error)`; the host's operation wrapper decides
  what to report.

## Build, Test, and Development Commands

- Setup: `bundle install`.
- Test: `bundle exec rspec` (offline, VCR-backed) or `bundle exec rake` (spec + rubocop).
- Lint: `bundle exec rubocop` (or `-A` to autocorrect — review every change).

## Coding Style & Conventions

- Ruby: 2-space indent; `snake_case` methods/vars; `CamelCase` classes.
- Operations: `Dkey::<Resource>::<Action>`, `include Dkey::Operation`, `def call(...)`, return
  `Dry::Monads::Result`, invoke with a fresh instance (`Op.new.call(...)` / `Op.new.call!(...)`).
- Validate arguments up front with `argument!` (`argument! 'Access ID is required.'`), one guard per line, before
  any network call.
- Keep all HTTP and response normalization in `Dkey`'s module functions and the operations; never leak wire
  decisions past the operation boundary.
- No `Rails`, no app constants — the gem stays framework-free (host injects config). ActiveSupport core extensions
  are fine.
- Telkey behaviour notes live in the `dkey` skill (`.agents/skills/dkey`); read it before changing endpoints,
  auth or retries.

## Testing Guidelines

- Stack: RSpec + VCR + WebMock, offline against recorded cassettes. A cassette folder keeps the wire name.
- An operation spec sets `let(:result) { described_class.new.call(**args) }` and asserts through the
  `successful call` (`value:`) and `failed call` (`failure_class:`, optional `let(:message)`)
  shared examples.
- Configure `Dkey` in the `spec_helper` `before` hook with the cassette-matching test credentials
  (`[TELKEY_API_KEY]`, `[TELKEY_API_SECRET]`, `[TELKEY_UNIT_ID]`, `[TELKEY_AUTH_TOKEN]`).
- Mirror the source tree: `spec/dkey/<resource>/<action>_spec.rb`.
- This repo is public: scrub real lock serials, codecard tokens and unit identifiers from a cassette before
  committing it.

## Commit & Pull Request Guidelines

- Commits: short, imperative subject with a conventional prefix: `feat:`, `fix:`, `chore:`, `dev:`, `misc:`,
  `test:`, `docs:`. Use scoped subjects when useful (e.g., `feat(access-grants): …`).
- PRs: clear description, linked issues, and a brief test plan. Ensure `bundle exec rake` passes.
- `staging` is the default branch; `production` tracks released gems.
