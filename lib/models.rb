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

  class Chat
    include Silueta

    attribute :messages
    attribute :buyer
    attribute :seller

    def self.build(messages, buyer: nil, seller: nil)
      message_models = []
      if buyer && seller
        message_models = messages.map do |message|
          Quickblox::Models::Message.new(
            created_at: message.fetch("created_at"),
            text: message.fetch("message"),
            dialog_id: message.fetch("chat_dialog_id"),
            sender: (message.fetch("sender_id") == buyer.id ? buyer : seller)
          )
        end
      end

      new(messages: message_models, buyer: buyer, seller: seller)
    end
  end

  class Message
    include Silueta

    attribute :created_at
    attribute :text
    attribute :dialog_id
    attribute :sender
  end
end

