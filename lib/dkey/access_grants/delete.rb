module Dkey
  module AccessGrants
    # Deactivates a codecard. Telkey deactivation is idempotent: re-revoking an
    # already-deactivated codecard still returns 200. (An unknown codecard id
    # returns 403, which surfaces as a failure.)
    class Delete
      include Dkey::Operation

      # @rbs (attributes: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[bool]
      def call(attributes:)
        argument! 'External ID is required.' if attributes[:external_id].blank?
        argument! 'Regular grants are not supported by the Telkey provider.' unless attributes[:kind] == KIND_TIME_CONTROLLED

        deactivate_codecard(attributes)

        Success(true)
      end

      private

      # @rbs (::Hash[::Symbol, untyped] attributes) -> untyped
      def deactivate_codecard(attributes)
        path = format('lock/codecard/%<id>s/deactivate', id: ERB::Util.url_encode(attributes[:external_id]))

        Dkey.request(:patch, path)
      end
    end
  end
end
