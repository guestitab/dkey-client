RSpec.describe Dkey::Locks::Index do
  let(:result) { described_class.new.call }

  context 'with a configured unit', vcr: { cassette_name: 'locks/index' } do
    it_behaves_like 'successful call',
                    value: [
                      { external_id: 'DEMO01', name: 'DEMO01', status: 'online', charge: nil, keys: [{ external_id: 'DEMO01', name: 'DEMO01' }] },
                      { external_id: 'DEMO02', name: 'Front door', status: 'online', charge: nil, keys: [{ external_id: 'DEMO02', name: 'Front door' }] },
                      { external_id: 'DEMO03', name: 'DEMO03', status: 'online', charge: nil, keys: [{ external_id: 'DEMO03', name: 'DEMO03' }] }
                    ]
  end

  context 'without a configured unit' do
    let(:message) { 'Dkey unit_id is not configured.' }

    before { Dkey.config.unit_id = nil }

    it_behaves_like 'failed call', failure_class: Dkey::Error
  end
end
