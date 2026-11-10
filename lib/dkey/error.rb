module Dkey
  class Error < StandardError; end

  # Raised by operations before any network call when the arguments are unusable.
  class ArgumentError < Error; end
end
