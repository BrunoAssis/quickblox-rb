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

  class User
    include Silueta

    attribute :id, cast: Types::Integer
    attribute :full_name
    attribute :email
    attribute :login
    attribute :phone

    def self.build(hash)
      email = hash.fetch("email") || JSON.parse(hash.fetch("custom_data")).fetch("email")
      new(
        id: hash.fetch("id"),
        full_name: hash.fetch("full_name"),
        email: email,
        login: hash.fetch("login"),
        phone: hash.fetch("phone")
      )
    end
  end
end

