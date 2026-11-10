RSpec.describe Dkey::AccessGrants::Create do
  let(:result) { described_class.new.call(**args) }

  let(:args) { { attributes: } }
  let(:attributes) { { kind:, access_id:, label:, start_date:, end_date: } }
  let(:access_id) { 'DEMOLOCK' }
  let(:kind) { 'tca' }
  let(:label) { 'Guest' }
  let(:start_date) { Time.zone.local(2026, 8, 1, 14) }
  let(:end_date) { Time.zone.local(2026, 8, 2, 14) }

  context 'with valid arguments', vcr: { cassette_name: 'access_grants/create' } do
    it_behaves_like 'successful call', value: {
      external_id: '00001111222233334444555566667777',
      metadata: { raw: { link: 'https://test.telkey.com/a/00001111222233334444555566667777' } }
    }
  end

  context 'when delivery times out' do
    let(:endpoint) { 'https://test.telkey.com/api/v2/lock/codecard' }
    let(:message) { 'creation timed out' }

    before do
      stub_request(:put, endpoint).to_raise(Faraday::TimeoutError.new(message))

      result
    end

    it_behaves_like 'failed call', failure_class: Faraday::TimeoutError

    it 'does not retry the codecard creation' do
      expect(WebMock).to have_requested(:put, endpoint).once
    end
  end

  context 'with invalid arguments' do
    context 'when the kind is unsupported' do
      let(:kind) { 'regular' }
      let(:message) { 'Regular grants are not supported by the Telkey provider.' }

      it_behaves_like 'failed call', failure_class: Dkey::ArgumentError
    end

    context 'when the access_id is blank' do
      let(:access_id) { nil }
      let(:message) { 'Access ID is required.' }

      it_behaves_like 'failed call', failure_class: Dkey::ArgumentError
    end

    context 'when the end_date is blank' do
      let(:end_date) { nil }
      let(:message) { 'Start date and end date are both required.' }

      it_behaves_like 'failed call', failure_class: Dkey::ArgumentError
    end

    context 'when the end_date is before the start_date' do
      let(:start_date) { Time.zone.local(2026, 8, 2, 14) }
      let(:end_date) { Time.zone.local(2026, 8, 1, 14) }
      let(:message) { 'End date must be after start date.' }

      it_behaves_like 'failed call', failure_class: Dkey::ArgumentError
    end
  end
end
