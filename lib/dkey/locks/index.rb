module Dkey
  module Locks
    # Lists the unit's locks. Telkey has no lock list filters and no paging: one
    # call returns every lock of the configured unit.
    class Index
      include Dkey::Operation

      # The wire reports no connectivity or battery level, so a listed lock reads
      # as online and the charge is left blank.
      STATUS_ONLINE = 'online'.freeze

      # @rbs () -> Dry::Monads::Result[::Array[::Hash[::Symbol, untyped]]]
      def call
        unit_id = Dkey.config.unit_id.presence || raise(Error, 'Dkey unit_id is not configured.')

        body = Dkey.request(:get, "lock/unit/#{unit_id}")

        Success(locks(body).map { |item| attributes(item) })
      end

      private

      # @rbs (::Hash[::Symbol, untyped] body) -> ::Array[::Hash[::Symbol, untyped]]
      def locks(body)
        body.dig(:data, :locks).presence || []
      end

      # Labels are often empty, so fall back to the serial number.

      # @rbs (::Hash[::Symbol, untyped] item) -> ::Hash[::Symbol, untyped]
      def attributes(item)
        name = item[:label].presence || item[:serialNumber]

        {
          external_id: item[:serialNumber],
          name:,
          status: STATUS_ONLINE,
          charge: nil,
          keys: [{ external_id: item[:serialNumber], name: }]
        }
      end
    end
  end
end
