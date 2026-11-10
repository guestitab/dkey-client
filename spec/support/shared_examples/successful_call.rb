RSpec.shared_examples 'successful call' do |value:|
  it 'completes successfully and returns the expected data' do
    expect(result).to be_success
    expect(result.value!).to eq(value)
  end
end
