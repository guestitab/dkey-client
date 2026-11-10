RSpec.describe Dkey::AccessGrants::Delete do
  let(:result) { described_class.new.call(**args) }

  let(:args) { { attributes: } }
  let(:attributes) { { kind:, external_id: } }
  let(:kind) { 'tca' }
  let(:external_id) { '00001111222233334444555566667777' }

  context 'with valid arguments', vcr: { cassette_name: 'access_grants/delete' } do
    it_behaves_like 'successful call', value: true
  end

  context 'with invalid arguments' do
    context 'when the kind is unsupported' do
      let(:kind) { 'regular' }
      let(:message) { 'Regular grants are not supported by the Telkey provider.' }

      it_behaves_like 'failed call', failure_class: Dkey::ArgumentError
    end

    context 'when the external_id is blank' do
      let(:external_id) { nil }
      let(:message) { 'External ID is required.' }

      it_behaves_like 'failed call', failure_class: Dkey::ArgumentError
    end
  end
end
