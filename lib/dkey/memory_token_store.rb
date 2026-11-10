module Dkey
  # Default in-memory auth-token store. A process restart re-logs in; a host that
  # needs the token shared across processes or surviving restarts injects its own
  # store with the same read/save contract (see Dkey.configure).
  class MemoryTokenStore
    Token = Struct.new(:access_token, :expires_at, keyword_init: true) do
      def expired?
        expires_at < Time.now
      end
    end

    # @rbs () -> Token?
    def read
      @token if @token && !@token.expired?
    end

    # @rbs (access_token: ::String, expires_at: untyped) -> Token
    def save(access_token:, expires_at:)
      @token = Token.new(access_token:, expires_at:)
    end
  end
end
