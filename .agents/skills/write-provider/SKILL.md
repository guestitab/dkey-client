---
name: write-provider
description: "Add or change a Telkey endpoint: the wire operation in the dkey-client gem, with VCR or WebMock specs."
---

# Write provider

## Choose where the change goes

- Wire calls, request shapes, retries, auth and response normalization live in this gem as
  `Dkey::<Resource>::<Action>`. Domain mapping, persistence, imports and jobs live in the host app. A new or
  changed endpoint is a gem change; a new use of an existing endpoint is a host change.
- Load the `dkey` skill for the API behaviour facts before changing endpoints, auth or retries.

## Gem operation

```ruby
module Dkey
  module AccessGrants
    class Create
      include Dkey::Operation

      # @rbs (attributes: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(attributes:)
        argument! 'Access ID is required.' if attributes[:access_id].blank?

        body = Dkey.request(:put, 'lock/codecard', params: payload(attributes))

        Success(external_id: codecard_id(body), metadata: { raw: body })
      end
    end
  end
end
```

- `#call` returns a `Dry::Monads::Result` and never raises; `#call!` unwraps and raises. Invoke with a fresh
  instance: `Op.new.call(...)` / `Op.new.call!(...)`.
- Validate arguments up front with `argument!`, one guard per line, before any network call. A refusal is a
  sentence the host can show as it is.
- `Dkey.request` owns the Faraday connection, retries, the `X-User-Id`/`X-Auth-Token` headers and the `ApiError`
  wrap; an operation never builds its own client. `AccessTokens::Upsert` posts the login through it
  with `headers: {}`, since the auth headers come from the token it is minting.
- Auth tokens persist through the injected token store (`read` / `save(access_token:, expires_at:)`); a new call
  that needs auth goes through `Dkey.request` and never mints a token itself.
- Normalize the response inside the operation (snake_case keys; kinds from the `Dkey::AccessGrants` constants) so
  the host reads one shape. Keep the raw wire body under `metadata[:raw]` when the host needs the rest of it (the
  codecard share link is the example).
- A non-idempotent write sends once: the retry middleware never retries `post` or `put`. After a failed write,
  `ApiError#unapplied?` separates "did not land" from "delivery unknown". The host records an explicit state and
  reconciles by exact provider identity before retrying.
- Declare the public API in `sig/dkey.rbs`.

## Spec

```ruby
RSpec.describe Dkey::AccessGrants::Create do
  let(:result) { described_class.new.call(**args) }

  let(:args) { { attributes: } }
  let(:attributes) { { kind: 'tca', access_id:, start_date:, end_date: } }

  context 'with valid arguments', vcr: { cassette_name: 'access_grants/create' } do
    it_behaves_like 'successful call', value: {
      external_id: '00001111222233334444555566667777',
      metadata: { raw: { link: 'https://test.telkey.com/a/00001111222233334444555566667777' } }
    }
  end

  context 'when the connection fails during creation' do
    let(:endpoint) { 'https://test.telkey.com/api/v2/lock/codecard' }
    let(:message) { 'creation connection failed' }

    before do
      stub_request(:put, endpoint).to_raise(Faraday::ConnectionFailed.new(message))

      result
    end

    it_behaves_like 'failed call', failure_class: Faraday::ConnectionFailed

    it 'does not retry the codecard creation' do
      expect(WebMock).to have_requested(:put, endpoint).once
    end
  end

  context 'with invalid arguments' do
    context 'when the access_id is blank' do
      let(:attributes) { super().merge(access_id: nil) }
      let(:message) { 'Access ID is required.' }

      it_behaves_like 'failed call', failure_class: Dkey::ArgumentError
    end
  end
end
```

- Stack: RSpec + VCR + WebMock, offline. Mirror the source tree: `spec/dkey/<resource>/<action>_spec.rb`,
  cassettes in `spec/fixtures/cassettes/<wire-name>/...`.
- Cover blank-argument refusals, the happy path against a cassette or an exact WebMock stub (status, body and
  content type mirror the transport) and the absence of retries on a write. Status refusals and `unapplied?` are
  covered once in `spec/dkey_spec.rb`; an operation spec does not repeat them.
- Cassette recording makes live Telkey calls and needs the owner's go-ahead first. An unmatched
  VCR interaction is evidence of request drift until a comparison of method, path, query, body and response
  envelope explains it. After authorized recording, keep only the interactions the spec uses; the `spec_helper`
  filters replace the credentials with `[TELKEY_API_KEY]` / `[TELKEY_API_SECRET]` / `[TELKEY_UNIT_ID]` /
  `[TELKEY_AUTH_TOKEN]`, and scrub any real lock serials or codecard tokens from the cassette before committing —
  this repo is public.

## Verify

```bash
bundle exec rspec spec/dkey/<resource>/<action>_spec.rb
bundle exec rake   # spec + rubocop
```
