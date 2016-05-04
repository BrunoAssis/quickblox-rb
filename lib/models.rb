require "silueta"
require "silueta/types"

module Silueta::Types
  require "date"

  DateTime = ->(value) { value && ::DateTime.parse(value) }
end

module Quickblox::Models
  class Session
    include Silueta

    attribute :token
    attribute :user_id, cast: Types::Integer
    attribute :expiration, cast: Types::DateTime

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
    attribute :tags

    def self.build(hash)
      email = hash.fetch("email") || JSON.parse(hash.fetch("custom_data")).fetch("email")
      new(
        id: hash.fetch("id"),
        full_name: hash.fetch("full_name"),
        email: email,
        login: hash.fetch("login"),
        phone: hash.fetch("phone"),
        tags: hash.fetch("user_tags")
      )
    end
  end

  class Chat
    include Silueta

    attribute :messages
    attribute :occupants
    attribute :dialog

    def self.build(messages:, occupants:, dialog: nil)
      messages.each do |message|
        sender = occupants.find { |occupant| occupant.id == message.sender_id }
        message.sender = sender
      end

      new(messages: messages, occupants: occupants, dialog: dialog)
    end
  end

  class Dialog
    include Silueta

    attribute :id
    attribute :occupants_ids
    attribute :type, cast: Types::Integer
    attribute :created_at, cast: Types::DateTime
    attribute :updated_at, cast: Types::DateTime

    def self.build(hash)
      new(
        id: hash.fetch("_id"),
        occupants_ids: hash.fetch("occupants_ids"),
        type: hash.fetch("type"),
        created_at: hash.fetch("created_at"),
        updated_at: hash.fetch("updated_at")
      )
    end
  end

  class Message
    include Silueta

    attribute :created_at, cast: Types::DateTime
    attribute :text
    attribute :dialog_id
    attribute :sender_id
    attribute :sender

    def self.batch_build(messages)
      messages.map { |message| build(message) }
    end

    def self.build(message)
      new(
        created_at: message.fetch("created_at"),
        text: message.fetch("message"),
        dialog_id: message.fetch("chat_dialog_id"),
        sender_id: message.fetch("sender_id")
      )
    end
  end
end

