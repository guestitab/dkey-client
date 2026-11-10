RSpec.describe Dkey do
  describe '.request' do
    let(:endpoint) { 'https://test.telkey.com/api/v2/lock/unit/test-unit-id' }

    context 'when Telkey answers' do
      before do
        stub_request(:get, endpoint)
          .to_return(status: 200, body: { data: { locks: [] }, status: 'success' }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'authenticates with the client id and the minted auth token' do
        described_class.request(:get, 'lock/unit/test-unit-id')

        expect(WebMock).to have_requested(:get, endpoint)
          .with(headers: { 'X-User-Id' => 'test-client-id', 'X-Auth-Token' => 'test-auth-token' })
      end
    end

    context 'when Telkey refuses the request' do
      before do
        stub_request(:get, endpoint)
          .to_return(status: 422, body: { error_code: '42200', error_message: 'invalid codecard', status: 'error' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises an ApiError carrying the status and the wire message' do
        expect { described_class.request(:get, 'lock/unit/test-unit-id') }
          .to raise_error(Dkey::ApiError, 'invalid codecard') { |error| expect(error.status).to eq(422) }
      end
    end

    context 'when Telkey glitches on a read' do
      let(:refusal) { { status: 503, body: '', headers: { 'Content-Type' => 'application/json' } } }

      before do
        stub_request(:get, endpoint).to_return(refusal, refusal, { status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' } })
      end

      it 'retries the request' do
        expect(described_class.request(:get, 'lock/unit/test-unit-id')).to eq({})
        expect(WebMock).to have_requested(:get, endpoint).times(3)
      end
    end

    context 'when Telkey glitches on a write' do
      before do
        stub_request(:put, 'https://test.telkey.com/api/v2/lock/codecard')
          .to_return(status: 503, body: '', headers: { 'Content-Type' => 'application/json' })
      end

      it 'does not retry the write' do
        expect { described_class.request(:put, 'lock/codecard', params: { locks: ['DEMOLOCK'] }) }
          .to raise_error(Dkey::ApiError)
        expect(WebMock).to have_requested(:put, 'https://test.telkey.com/api/v2/lock/codecard').once
      end
    end

    context 'without a client id' do
      before { described_class.config.client_id = nil }

      it 'refuses the call' do
        expect { described_class.request(:get, 'lock/unit/test-unit-id') }.to raise_error(Dkey::Error, 'Dkey client_id is required.')
      end
    end
  end

  describe Dkey::ApiError do
    def api_error(status)
      Dkey::ApiError.new('nope', status:)
    end

    describe '#unapplied?' do
      it 'holds for a refusal that proves the write never took' do
        expect(api_error(400).unapplied?).to be(true)
        expect(api_error(422).unapplied?).to be(true)
      end

      it 'leaves a timeout, a conflict and a server error unknown' do
        expect(api_error(408).unapplied?).to be(false)
        expect(api_error(409).unapplied?).to be(false)
        expect(api_error(500).unapplied?).to be(false)
      end
    end
  end
end
