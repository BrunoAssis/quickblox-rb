require "requests/sugar"
require "securerandom"
require "json"

class Quickblox
  QB_ENDPOINT = "https://api.quickblox.com".freeze
  QB_HEADER_API_VERSION = "QuickBlox-REST-API-Version".freeze

  attr :auth_key,
       :auth_secret,
       :application_id,
       :email,
       :password,
       :session

  def initialize(**args)
    @auth_key        = args.fetch(:auth_key)
    @auth_secret     = args.fetch(:auth_secret)
    @application_id = args.fetch(:application_id)
    @email          = args[:email]
    @password       = args[:password]
  end

  def create_session
    data = {
      "application_id" => application_id,
      "auth_key" => auth_key,
      "nonce" => SecureRandom.random_number(100000),
      "timestamp" => Time.now.to_i,
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

    if response.status == 201
      @session = response.json.fetch("session")
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
end

