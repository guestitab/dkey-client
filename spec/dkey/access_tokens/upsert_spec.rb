RSpec.describe Dkey::AccessTokens::Upsert do
  let(:result) { described_class.new.call }

  let(:store) { Dkey::MemoryTokenStore.new }
  let(:login_url) { 'https://test.telkey.com/api/v2/login' }
  let(:login_status) { 200 }
  let(:login_body) { { data: { authToken: 'fresh-token', userId: 'user-1' }, status: 'success' } }

  before do
    Dkey.config.token_store = store

    stub_request(:post, login_url)
      .with(body: { api_key: 'test-client-id', api_secret: 'test-secret' })
      .to_return(status: login_status, body: login_body.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  context 'with an active stored token' do
    before do
      store.save(access_token: 'stored-token', expires_at: 1.hour.from_now)

      result
    end

    it 'returns the stored token' do
      expect(result.value!).to have_attributes(access_token: 'stored-token')
    end

    it 'does not request a login' do
      expect(WebMock).not_to have_requested(:post, login_url)
    end
  end

  context 'without a stored token' do
    before { result }

    it 'logs in with the api credentials' do
      expect(WebMock).to have_requested(:post, login_url).with(body: { api_key: 'test-client-id', api_secret: 'test-secret' }).once
    end

    it 'stores the minted token for the token ttl' do
      expect(store.read).to have_attributes(access_token: 'fresh-token', expires_at: be_within(1.minute).of(described_class::TOKEN_TTL.from_now))
    end
  end

  context 'with an expired stored token' do
    before { store.save(access_token: 'expired-token', expires_at: 1.hour.ago) }

    it 're-mints the token' do
      expect(result.value!).to have_attributes(access_token: 'fresh-token')
    end
  end

  context 'when the login fails' do
    let(:login_status) { 401 }
    let(:login_body) { { error_code: '40100', error_message: 'Wrong email or password', status: 'error' } }
    let(:message) { 'Wrong email or password' }

    it_behaves_like 'failed call', failure_class: Dkey::ApiError
  end

  context 'when the login response has no auth token' do
    let(:login_body) { { data: {}, status: 'success' } }
    let(:message) { 'Dkey login response is missing an auth token.' }

    it_behaves_like 'failed call', failure_class: Dkey::Error
  end
end
