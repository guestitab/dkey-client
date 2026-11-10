module Dkey
  module AccessTokens
    # Logs in with the account's api credentials and stores the minted auth token.
    # The login response carries no expiry, so the token is held for TOKEN_TTL and
    # then re-minted.
    class Upsert
      include Dkey::Operation

      TOKEN_TTL = 12.hours

      # @rbs () -> Dry::Monads::Result[untyped]
      def call
        Success(store.read || mint)
      end

      private

      # @rbs () -> untyped
      def store
        Dkey.config.token_store
      end

      # @rbs () -> untyped
      def mint
        body = Dkey.request(:post, 'login', params: { api_key: Dkey.client_id, api_secret: Dkey.secret }, headers: {})

        store.save(access_token: auth_token(body), expires_at: TOKEN_TTL.from_now)
      end

      # @rbs (untyped body) -> ::String
      def auth_token(body)
        token = body.dig(:data, :authToken) if body.is_a?(Hash)

        token.presence || raise(Error, 'Dkey login response is missing an auth token.')
      end
    end
  end
end
