require_relative 'lib/dkey/version'

Gem::Specification.new do |spec|
  spec.name        = 'dkey-client'
  spec.version     = Dkey::VERSION
  spec.authors     = ['Guestit']
  spec.summary     = 'Ruby client for the Telkey (dKey) API'
  spec.description = 'One operation per Telkey dKey API endpoint, returning dry-monads Results, with retries and ' \
                     'response normalization. Framework-free: the host injects the account credentials, the unit ' \
                     'id and the auth-token store.'
  spec.license     = 'MIT'
  spec.homepage    = 'https://github.com/guestitab/dkey-client'
  spec.required_ruby_version = '>= 4.0'
  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['source_code_uri'] = 'https://github.com/guestitab/dkey-client'
  spec.metadata['changelog_uri'] = 'https://github.com/guestitab/dkey-client/blob/staging/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/guestitab/dkey-client/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = %w[CHANGELOG.md LICENSE README.md] + Dir['lib/**/*.rb'] + Dir['sig/**/*.rbs']
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '~> 8.1'
  spec.add_dependency 'dry-monads', '~> 1.10'
  spec.add_dependency 'faraday', '~> 2.14'
  spec.add_dependency 'faraday-retry', '~> 2.4'
  spec.add_dependency 'oj', '~> 3.17'
end
