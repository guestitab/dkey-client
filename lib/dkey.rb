require 'active_support'
require 'active_support/core_ext'
require 'dry/monads'
require 'erb'
require 'faraday'
require 'faraday/retry'
require 'oj'

require_relative 'dkey/version'
require_relative 'dkey/error'
require_relative 'dkey/api_error'
require_relative 'dkey/memory_token_store'
require_relative 'dkey/config'
require_relative 'dkey/operation'
require_relative 'dkey/client'
require_relative 'dkey/access_grants'
require_relative 'dkey/access_tokens/upsert'
require_relative 'dkey/access_grants/create'
require_relative 'dkey/access_grants/delete'
require_relative 'dkey/locks/index'

module Dkey
  class << self
    # @rbs () { (Config) -> void } -> void
    def configure
      yield(config)
    end

    # @rbs () -> Config
    def config
      @config ||= Config.new
    end
  end
end
