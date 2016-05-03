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
      },
    )

    @last_response = response

    if response.status == 200
      user = response.json.fetch("user")
      Quickblox::Models::User.build(user)
    end
  end

  def chat_transcript(dialog_id:)
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

    if response.status == 200
      messages = response.json.fetch("items")

      buyer, seller = [
        find_user(user_id: messages.first.fetch("sender_id")),
        find_user(user_id: messages.first.fetch("recipient_id"))
      ]

      Quickblox::Models::Chat.build(messages, buyer: buyer, seller: seller)
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
