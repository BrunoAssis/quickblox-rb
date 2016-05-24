require "requests/sugar"
require "securerandom"
require "json"

class Quickblox::API
  QB_ENDPOINT = "https://api.quickblox.com".freeze
  QB_HEADER_API_VERSION = "QuickBlox-REST-API-Version".freeze
  QB_HEADER_TOKEN = "QB-Token".freeze
  QB_HEADER_EXPIRATION = "qb-token-expirationdate".freeze

  attr :auth_key,
       :auth_secret,
       :application_id,
       :email,
       :password,
       :session,
       :last_response

  def initialize(**args)
    @auth_key       = args.fetch(:auth_key)
    @auth_secret    = args.fetch(:auth_secret)
    @application_id = args.fetch(:application_id)
    @email          = args[:email]
    @password       = args[:password]
  end

  def create_session
    data = {
      "application_id" => application_id,
      "auth_key"       => auth_key,
      "nonce"          => SecureRandom.random_number(100000),
      "timestamp"      => Time.now.to_i,
    }

    data["user[email]"] = email if email
    data["user[password]"] = password if password

    signature = sign(data)

    data["signature"] = signature

    response = Requests.post(
      QB_ENDPOINT + "/session.json",
      headers: { QB_HEADER_API_VERSION => "0.1.1" },
      data: data
    )

    @last_response = response

    if response.status == 201
      session = response.json.fetch("session")
      session["expiration"] = response.headers.fetch(QB_HEADER_EXPIRATION).first
      @session = Quickblox::Models::Session.build(session)
    end
  end

  def get_user(id:)
    response = Requests.get(
      QB_ENDPOINT + "/users/#{id}.json",
      headers: {
        QB_HEADER_API_VERSION => "0.1.1",
        QB_HEADER_TOKEN => session_token
      }
    )

    @last_response = response

    if response.status == 200
      user = response.json.fetch("user")
      Quickblox::Models::User.build(user)
    end
  end

  # You can only retrieve dialogs where the authenticated user is a participant!
  # But you can `get_messages` with the admin account, though.
  def get_dialog(id:)
    response = Requests.get(
      QB_ENDPOINT + "/chat/Dialog.json",
      headers: {
        QB_HEADER_API_VERSION => "0.1.1",
        QB_HEADER_TOKEN => session_token
      },
      params: {
        _id: id,
        type: 3
      }
    )

    @last_response = response

    if response.status == 200
      dialog = response.json.fetch("items").first

      if dialog
        Quickblox::Models::Dialog.build(dialog)
      end
    end
  end

  def get_messages(dialog_id:)
    response = Requests.get(
      QB_ENDPOINT + "/chat/Message.json",
      headers: {
        QB_HEADER_API_VERSION => "0.1.1",
        QB_HEADER_TOKEN => session_token
      },
      params: {
        chat_dialog_id: dialog_id,
        mark_as_read: 0
      }
    )

    @last_response = response

    if response.status == 200
      messages = response.json.fetch("items")

      Quickblox::Models::Message.batch_build(messages)
    end
  end

  def get_dialogs
    response = Requests.get(
      QB_ENDPOINT + "/chat/Dialog.json",
      headers: {
        QB_HEADER_API_VERSION => "0.1.1",
        QB_HEADER_TOKEN => session_token
      },
      params: {
        type: 3
      }
    )

    @last_response = response

    if response.status == 200
      dialogs = response.json.fetch("items")

      if dialogs && !dialogs.empty?
        Quickblox::Models::Dialog.batch_build(dialogs)
      end
    end
  end

  def chat_transcript(dialog_id:)
    messages = get_messages(dialog_id: dialog_id)
    occupant_ids = messages.map(&:sender_id).uniq
    occupants = occupant_ids.map { |id| get_user(id: id) }

    Quickblox::Models::Chat.build(messages: messages, occupants: occupants)
  end

  def chat_transcripts(dialogs:)
    dialogs.map do |dialog|
      messages = get_messages(dialog_id: dialog.id)
      occupants = dialog.occupants_ids.map { |id| get_user(id: id) }

      Quickblox::Models::Chat.build(messages: messages,
                                    occupants: occupants,
                                    dialog: dialog)
    end
  end

private

  def sign(data)
    normalized_string = data.each_key
      .sort
      .map { |key| "#{key}=#{data[key]}" }
      .join("&")

    sha1 = OpenSSL::Digest::SHA1.new
    OpenSSL::HMAC.hexdigest(sha1, auth_secret, normalized_string)
  end

  def session_token
    (@session || create_session).token
  end
end

