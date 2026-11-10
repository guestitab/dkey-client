module Dkey
  # Injected by the host app (see the Dkey.configure initializer): the account's
  # client id (the api_key, which doubles as the X-User-Id header value), the
  # secret (api_secret), the unit every lock call scopes to, and the store the
  # minted auth token persists in. Keeping these out of the gem is what makes it
  # host-agnostic.
  #
  # Telkey mints an auth token per login, so unlike a static-token provider the
  # gem needs a token store; the default MemoryTokenStore keeps it per process.
  class Config
    attr_accessor :client_id, :secret, :unit_id, :base_url, :timeout, :token_store

    def initialize
      @base_url = BASE_URL
      @token_store = MemoryTokenStore.new
    end
  end
end
