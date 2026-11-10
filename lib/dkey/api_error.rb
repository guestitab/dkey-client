module Dkey
  # A rejected Telkey response, carrying the HTTP status. #unapplied? marks a
  # refusal where the write certainly did not land, so a retry is safe; anything
  # else (a server error, a timeout after a write) leaves delivery unknown.
  class ApiError < Error
    attr_reader :status #: ::Integer

    # @rbs (::String message, status: ::Integer) -> void
    def initialize(message, status:)
      super(message)

      @status = status
    end

    # @rbs () -> bool
    def unapplied?
      status.between?(400, 499) && [408, 409].exclude?(status)
    end
  end
end
