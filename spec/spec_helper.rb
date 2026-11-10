require 'dkey'
require 'vcr'
require 'webmock/rspec'

Dir[File.expand_path('support/**/*.rb', __dir__)].each { |file| require file }

# The time zone the cassettes were recorded in, so Time.zone.local builds the same instants.
Time.zone = 'Europe/Stockholm'

# Test credentials. The filters below swap them for the cassettes' placeholders.
DKEY_TEST_CREDENTIALS = {
  client_id: 'test-client-id',
  secret: 'test-secret',
  unit_id: 'test-unit-id',
  base_url: 'https://test.telkey.com/api/v2/',
  auth_token: 'test-auth-token'
}.freeze

VCR.configure do |config|
  config.cassette_library_dir = File.expand_path('fixtures/cassettes', __dir__)
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    allow_unused_http_interactions: false,
    match_requests_on: %i[method uri body]
  }

  config.filter_sensitive_data('[TELKEY_API_KEY]') { DKEY_TEST_CREDENTIALS[:client_id] }
  config.filter_sensitive_data('[TELKEY_API_SECRET]') { DKEY_TEST_CREDENTIALS[:secret] }
  config.filter_sensitive_data('[TELKEY_UNIT_ID]') { DKEY_TEST_CREDENTIALS[:unit_id] }
  config.filter_sensitive_data('[TELKEY_AUTH_TOKEN]') { DKEY_TEST_CREDENTIALS[:auth_token] }
end

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.disable_monkey_patching!

  config.before do
    Dkey.configure do |dkey|
      dkey.client_id = DKEY_TEST_CREDENTIALS[:client_id]
      dkey.secret = DKEY_TEST_CREDENTIALS[:secret]
      dkey.unit_id = DKEY_TEST_CREDENTIALS[:unit_id]
      dkey.base_url = DKEY_TEST_CREDENTIALS[:base_url]
      dkey.token_store = Dkey::MemoryTokenStore.new
      dkey.token_store.save(access_token: DKEY_TEST_CREDENTIALS[:auth_token], expires_at: 1.hour.from_now)
    end
  end
end
