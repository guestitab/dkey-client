# dkey-client

A Ruby client for the [Telkey (dKey) API](https://manager.telkey.com/api/v2/). Each endpoint is one operation class
that returns a [dry-monads](https://dry-rb.org/gems/dry-monads/) `Result`. The gem handles authentication, retries
and response normalization. It does not depend on Rails, only on ActiveSupport and Faraday. Your app supplies the
account credentials, the unit id and the auth-token store.

[Guestit](https://guestit.se) built it and runs it in production.

Requires Ruby 4.0 or later.

## Installation

```ruby
# Gemfile
gem 'dkey-client'
```

Bundler loads it for you. Outside Bundler, `require 'dkey'`.

## Configuration

```ruby
Dkey.configure do |config|
  config.client_id   = ENV.fetch('TELKEY_CLIENT_ID') # the api_key; doubles as the X-User-Id header
  config.secret      = ENV.fetch('TELKEY_SECRET')    # the api_secret
  config.unit_id     = ENV.fetch('TELKEY_UNIT_ID')
  config.token_store = MyTokenStore.new              # optional, defaults to Dkey::MemoryTokenStore
end
```

| Setting | Default | What it does |
| --- | --- | --- |
| `client_id` | `nil` | The account's api key, sent as the `X-User-Id` header and used to log in. |
| `secret` | `nil` | The account's api secret, used to log in. |
| `unit_id` | `nil` | The unit every lock listing scopes to. |
| `base_url` | `https://manager.telkey.com/api/v2/` | API root. |
| `timeout` | `nil` | Faraday request timeout in seconds. |
| `token_store` | `Dkey::MemoryTokenStore.new` | Where the minted auth token persists. |

## Auth tokens

Telkey mints an auth token on `POST login` and the response carries no expiry, so the gem holds a token for 12
hours and then logs in again. Every authenticated call sends `X-User-Id` (the client id) and `X-Auth-Token` (the
minted token); `AccessTokens::Upsert` reads the store first and only logs in when the stored token is missing or
expired.

A token store answers `read` (the token or `nil`) and `save(access_token:, expires_at:)`; a token responds to
`access_token` and `expired?`. The default `Dkey::MemoryTokenStore` keeps the token per process — inject a real
store to share it across processes or survive deploys.

## Usage

Operations live under `Dkey::<Resource>::<Action>`. Build a fresh instance for every call:

```ruby
result = Dkey::Locks::Index.new.call

if result.success?
  result.value!   # => [{ external_id: 'A1B2C3', name: 'Front door', status: 'online', charge: nil, keys: [...] }]
else
  result.failure  # => a Dkey::Error or a Faraday::Error
end
```

`call` never raises. It returns `Success(value)` or `Failure(error)`. `call!` returns the `Success` and raises the
error where `call` would return a `Failure`. Response bodies come back as hashes with symbol keys.

The gem covers codecards (`AccessGrants::Create`, `AccessGrants::Delete`), the unit's locks (`Locks::Index`) and
the login (`AccessTokens::Upsert`, which the client calls for you). [CHANGELOG.md](CHANGELOG.md) lists every
operation.

### Grants and locks

A grant is a codecard: a time-bound guest link for one lock. Telkey has no reusable keys and no permanent grants,
so only the time-controlled kind (`kind: 'tca'`) is supported, always with a validity window; anything else is
refused before any request:

```ruby
Dkey::AccessGrants::Create.new.call(
  attributes: {
    access_id: 'A1B2C3', # the lock's serial number
    kind: 'tca',
    label: 'Guest',
    start_date: Time.utc(2026, 11, 10),
    end_date: Time.utc(2026, 11, 12)
  }
)
```

`Create` returns only a share link (`https://…/a/<token>`); the token is the codecard id the `Delete` call
deactivates, and the full link rides along in `metadata[:raw]` for the guest. Deactivation is idempotent:
re-revoking an already-deactivated codecard still returns 200, while an unknown id answers 403.

`Locks::Index` returns every lock of the configured unit in one call — Telkey has no filters and no paging. The
wire reports no connectivity or battery level, so a listed lock reads as `online` with a blank charge, and an
empty lock label falls back to the serial number.

### Errors

| Class | Raised when |
| --- | --- |
| `Dkey::ArgumentError` | The arguments are unusable. Raised before any request, with a message the host can show as it is. |
| `Dkey::ApiError` | Telkey answered with an error status. `#status` holds the HTTP status. |
| `Dkey::Error` | The parent of the two above, also raised when the client id, secret or unit id is missing. |

### Retries and delivery

Reads retry 429/502/503/504, timeouts and connection-level failures with backoff. A codecard create and the login
never retry, since `PUT /lock/codecard` has no provider idempotency key. The deactivation is idempotent and retries
a connection-level failure only. After a failed write:

```ruby
error.is_a?(Dkey::ApiError) && error.unapplied? # the write certainly did not take, so a retry is safe
```

Anything else (a server error, a timeout after the request left) leaves delivery unknown: read back before
retrying.

## Type signatures

The gem ships RBS for its public API in `sig/dkey.rbs`. `rbs collection install` picks it up from your
`Gemfile.lock`, so Steep sees it with no extra setup.

## Development

```sh
bundle install
bundle exec rake        # specs and RuboCop
bundle exec rspec       # specs only
bundle exec rubocop -A  # autocorrect; review every change
```

The specs run offline against recorded VCR cassettes in `spec/fixtures/cassettes`. Recording a new cassette needs
live credentials for a Telkey account. Scrub the client id, the secret, the unit id and the auth token (the
spec_helper filters handle all four) and any real lock serials or codecard tokens from the cassette before you
commit it — this repo is public.

## Releasing

1. Bump `Dkey::VERSION` in `lib/dkey/version.rb` and move the `Unreleased` notes in `CHANGELOG.md` under the new
   version.
2. Commit on `staging` and run `bundle exec rake`.
3. Run `gem signin` once per machine. The gem requires MFA, so every push asks for a one-time code.
4. Run `bundle exec rake release`. It builds `pkg/dkey-client-<version>.gem`, tags `v<version>`, pushes the branch
   and the tag, and pushes the gem to RubyGems.
5. Fast-forward `production` to the release tag.

## License

MIT. See [LICENSE](LICENSE).
