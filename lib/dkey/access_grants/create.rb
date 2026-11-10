module Dkey
  module AccessGrants
    # Creates a codecard: a time-bound guest link for one lock. Telkey has no
    # reusable keys and no permanent grants, so only the time-controlled kind is
    # supported, always with a validity window.
    class Create
      include Dkey::Operation

      # @rbs (attributes: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(attributes:)
        argument! 'Access ID is required.' if attributes[:access_id].blank?
        argument! 'Regular grants are not supported by the Telkey provider.' unless attributes[:kind] == KIND_TIME_CONTROLLED
        argument! 'Start date and end date are both required.' if attributes[:start_date].blank? || attributes[:end_date].blank?
        argument! 'End date must be after start date.' if attributes[:start_date].in_time_zone >= attributes[:end_date].in_time_zone

        Success(create_codecard(attributes))
      end

      private

      # @rbs (::Hash[::Symbol, untyped] attributes) -> ::Hash[::Symbol, untyped]
      def create_codecard(attributes)
        data = codecard_data(Dkey.request(:put, 'lock/codecard', params: codecard_payload(attributes)))
        external_id = codecard_id(data)
        raise Error, 'Dkey codecard id is required' if external_id.blank?

        { external_id:, metadata: { raw: data } }
      end

      # @rbs (::Hash[::Symbol, untyped] attributes) -> ::Hash[::Symbol, untyped]
      def codecard_payload(attributes)
        {
          valid_from: iso8601(attributes[:start_date]),
          valid_to: iso8601(attributes[:end_date]),
          locks: [attributes[:access_id]],
          label: attributes[:label].presence,
          key_type: 0
        }.compact
      end

      # @rbs (::Hash[::Symbol, untyped] body) -> ::Hash[::Symbol, untyped]
      def codecard_data(body)
        body.is_a?(Hash) ? (body[:data].presence || {}) : {}
      end

      # Telkey returns only a share link (https://…/a/<token>); the <token> is the codecard id
      # used to deactivate it later. The full link is kept in metadata for the guest.

      # @rbs (::Hash[::Symbol, untyped] data) -> ::String?
      def codecard_id(data)
        link = data[:link]
        return if link.blank?

        link[%r{/a/([^/?#]+)}, 1] || link[%r{/([^/?#]+)/?\z}, 1]
      end

      # @rbs ((::Date | ::Time) value) -> ::String
      def iso8601(value)
        value.in_time_zone.utc.iso8601
      end
    end
  end
end
