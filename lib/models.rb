require "silueta"
require "silueta/types"

module Quickblox::Models
  class Session
    include Silueta

    attribute :token
    attribute :user_id, cast: Types::Integer
    attribute :expiration, cast: ->(value) { value && DateTime.parse(value) }
  end
end

