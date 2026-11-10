module Dkey
  BASE_URL = 'https://manager.telkey.com/api/v2/'.freeze #: ::String

  CONNECTION_LEVEL_ERRORS = [Faraday::ConnectionFailed, Faraday::SSLError].freeze #: ::Array[untyped]

  # A codecard PUT creates a grant without a provider idempotency key and the
  # login POST mints a token, so neither ever retries. A read retries a refused
  # status, a timeout and a connection-level failure. The deactivation PATCH is
  # idempotent and retries a connection-level failure only.
  RETRY_OPTIONS = {
    max: 3,
    interval: 0.5,
    interval_randomness: 0.5,
    backoff_factor: 2,
    retry_statuses: [429, 502, 503, 504],
    methods: Faraday::Retry::Middleware::IDEMPOTENT_METHODS - [:put],
    exceptions: [*Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS, *CONNECTION_LEVEL_ERRORS],
    retry_if: ->(env, exception) do
      next false if %i[post put].include?(env.method)

      CONNECTION_LEVEL_ERRORS.any? { |klass| exception.is_a?(klass) }
    end
  }.freeze #: ::Hash[::Symbol, untyped]

  # @rbs () -> Faraday::Connection
  def self.connection
    @connection ||= Faraday.new(url: config.base_url, headers: { 'Accept' => 'application/json' }) do |builder|
      builder.request :json
      builder.request :retry, RETRY_OPTIONS
      builder.response :json, parser_options: { symbolize_names: true, mode: :rails, decoder: [Oj, :load] }
      builder.options[:timeout] = config.timeout
    end
  end

  # @rbs (::Symbol method, ::String path, ?params: untyped, ?headers: ::Hash[::String, ::String]) -> untyped
  def self.request(method, path, params: nil, headers: auth_headers)
    response = connection.public_send(method, path, params, headers)

    return response.body if response.success?

    raise ApiError.new(error_message(response), status: response.status)
  end

  # Telkey identifies the account by its api_key, which doubles as the X-User-Id header value.

  # @rbs () -> ::String
  def self.client_id
    config.client_id.presence || raise(Error, 'Dkey client_id is required.')
  end

  # @rbs () -> ::String
  def self.secret
    config.secret.presence || raise(Error, 'Dkey secret is required.')
  end

  # @rbs () -> ::Hash[::String, ::String]
  private_class_method def self.auth_headers
    { 'X-User-Id' => client_id, 'X-Auth-Token' => AccessTokens::Upsert.new.call!.value!.access_token }
  end

  # Telkey returns error details under :error_message.

  # @rbs (Faraday::Response response) -> ::String
  private_class_method def self.error_message(response)
    body = response.body
    message = body.is_a?(Hash) ? body[:error_message] : nil

    message.presence || body.to_s.presence || "Provider request failed with status #{response.status}"
  end
end
