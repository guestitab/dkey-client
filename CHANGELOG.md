# Changelog

## Unreleased

## 0.1.0

- Initial release, extracted from Guestit Core's `Providers::Stargate::Dkey`.
- `Dkey::AccessGrants::Create` — `PUT lock/codecard`, time-controlled codecards only.
- `Dkey::AccessGrants::Delete` — `PATCH lock/codecard/:id/deactivate`, idempotent.
- `Dkey::Locks::Index` — `GET lock/unit/:unit_id`, the unit's locks in one call.
- `Dkey::AccessTokens::Upsert` — `POST login`, mints and stores the auth token via the injected token store.
