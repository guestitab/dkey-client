module Dkey
  # Shared monadic contract for the client operations: #call returns a Result,
  # #call! unwraps it and raises the underlying failure. An error raised inside
  # #call becomes Failure(error), mirroring the host's operation base.
  module Operation
    def self.included(base)
      base.include Dry::Monads[:result]
      base.prepend(Call)
    end

    module Call
      def call(*, **, &)
        super
      rescue StandardError => e
        Failure(e)
      end
    end

    def call!(...)
      result = call(...)
      raise result.failure if result.failure?

      result
    end

    private

    def argument!(message)
      raise Dkey::ArgumentError, message
    end
  end
end
