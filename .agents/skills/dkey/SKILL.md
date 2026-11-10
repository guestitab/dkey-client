---
name: dkey
description: "Dkey (Telkey) API behaviour: auth, tokens, retries, codecards and locks. Load before changing an endpoint, auth or retries, and before a live Telkey call or a cassette."
---

# Dkey (Telkey)

Dkey is Guestit's name for the Telkey access API: a unit's locks, and grants as time-bound codecards (guest links).
This gem is its wire client; the host app maps the results onto its own models.

## Calls and credentials

- Auth is two steps: `POST login` with `api_key` + `api_secret` mints an auth token, and every other call sends
  `X-User-Id` (the api key — Telkey identifies the account by it) and `X-Auth-Token`. The login response carries
  no expiry; the gem holds a token for 12 hours and re-logs in, persisting through the injected token store. A
  token reaches a live account: a call with real credentials reads and writes real codecards.
- The base URL differs per environment: `https://test.telkey.com/api/v2/` vs `https://manager.telkey.com/api/v2/`.
- Errors come back as `{ error_code:, error_message:, status: 'error' }`; `Dkey::ApiError` carries the
  `error_message` and the HTTP status.
- A read retries 429/502/503/504, timeouts and connection-level failures with backoff. A codecard create and the
  login never retry, since `PUT /lock/codecard` has no provider idempotency key. The deactivation is idempotent and
  retries a connection-level failure only. After a failed write,
  `Dkey::ApiError#unapplied?` (a 4xx other than 408/409) means it did not land and a retry is safe; anything else
  leaves delivery unknown.

## Codecards and locks

- A grant is a codecard: `PUT /lock/codecard` with `valid_from`, `valid_to`, `locks: [serial]`, `label` and
  `key_type: 0`. Telkey issues only time-bound codecards — there are no reusable keys and no permanent grants, so
  the gem supports only the time-controlled kind (`tca`) and refuses anything else before the wire.
- Telkey returns only a share link (`https://…/a/<token>`); the `<token>` is the codecard id used to deactivate it
  later, and the full link is kept in `metadata[:raw]` for the guest.
- Deactivation is `PATCH /lock/codecard/:id/deactivate` and is idempotent: re-revoking an already-deactivated
  codecard still returns 200, while an unknown codecard id returns 403.
- `Locks::Index` is `GET /lock/unit/:unit_id`: one call, every lock of the unit, no filters and no paging. The
  wire reports no connectivity or battery level, so a listed lock reads as `online` with a blank charge, and an
  empty lock label falls back to the serial number.
- There is no grant list endpoint and no webhook: the host owns grant state once a codecard is issued.
