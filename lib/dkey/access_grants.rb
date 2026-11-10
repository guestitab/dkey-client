module Dkey
  # Telkey issues only time-bound codecards, so the one grant kind the
  # access-grant operations accept is time-controlled (tca). The host passes its
  # own grant vocabulary through and gets a refusal before the wire for any
  # other kind.
  module AccessGrants
    KIND_TIME_CONTROLLED = 'tca'.freeze #: ::String
  end
end
