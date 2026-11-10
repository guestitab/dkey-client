# Set `let(:message)` to a String or a Regexp to pin the failure message.
RSpec.shared_examples 'failed call' do |failure_class:|
  it 'fails with the exception' do
    expect(result).to be_failure
    expect(result.failure).to be_a(failure_class)
    expect(result.failure.message).to match(message) if defined?(message)
  end
end
