require "silueta"
require "silueta/types"

module Quickblox::Models
  class Session
    include Silueta

    attribute :token
    attribute :user_id, cast: Types::Integer
    attribute :expiration, cast: ->(value) { value && DateTime.parse(value) }

    def self.build(hash)
      new(
        token: hash.fetch("token"),
        user_id: hash.fetch("user_id"),
        expiration: hash.fetch("expiration")
      )
    end
  end
end

