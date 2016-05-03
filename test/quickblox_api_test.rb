require "cutest"
require "mocoso"
require "quickblox"
require "date"
require_relative "quickblox_responses"

include Mocoso

scope "initialization" do
  test "with application credentials" do
    qb = Quickblox::API.new(
      auth_key: "AUTH_KEY",
      auth_secret: "AUTH_SECRET",
      application_id: 1234,
    )

    assert_equal "AUTH_KEY", qb.auth_key
    assert_equal "AUTH_SECRET", qb.auth_secret
    assert_equal 1234, qb.application_id
    assert qb.email.nil?
    assert qb.password.nil?
  end

  test "with user credentials" do
    qb = Quickblox::API.new(
      auth_key: "AUTH_KEY",
      auth_secret: "AUTH_SECRET",
      application_id: 1234,
      email: "account@owner.com",
      password: "foobarbaz"
    )

    assert_equal "AUTH_KEY", qb.auth_key
    assert_equal "AUTH_SECRET", qb.auth_secret
    assert_equal 1234, qb.application_id
    assert_equal "account@owner.com", qb.email
    assert_equal "foobarbaz", qb.password
  end
end

test "#create_session" do
  qb = Quickblox::API.new(
    auth_key: "AUTH_KEY",
    auth_secret: "AUTH_SECRET",
    application_id: 1234,
    email: "account@owner.com",
    password: "foobarbaz"
  )

  # This is a real life example of a response to POST /session.json
  # We only care about the expiration header.
  mock_response = Requests::Response.new(
    201,
    { "qb-token-expirationdate" => ["2016-05-02 19:52:00 UTC"] },
    QB_RESPONSES.fetch(:session)
  )

  assert qb.session.nil?

  stub(Requests, :request, mock_response) { qb.create_session }

  assert qb.session
  assert_equal Quickblox::Models::Session, qb.session.class
  assert_equal "le-token-stuff", qb.session.token
  assert_equal DateTime.parse("2016-05-02 19:52:00 UTC"), qb.session.expiration
end

test "#last_response" do
  qb = Quickblox::API.new(
    auth_key: "AUTH_KEY",
    auth_secret: "AUTH_SECRET",
    application_id: 1234,
    email: "account@owner.com",
    password: "foobarbaz"
  )

  mock_response = Requests::Response.new(
    201,
    { "qb-token-expirationdate" => ["2016-05-02 19:52:00 UTC"] },
    "{\"session\": {\"token\":\"le-token\",\"user_id\":\"5\"}}"
  )

  assert qb.last_response.nil?

  stub(Requests, :request, mock_response) { qb.create_session }

  assert_equal mock_response, qb.last_response
end

test "#get_user" do
  qb = Quickblox::API.new(
    auth_key: "AUTH_KEY",
    auth_secret: "AUTH_SECRET",
    application_id: 1234,
    email: "account@owner.com",
    password: "foobarbaz"
  )

  mock_response = Requests::Response.new(200, {}, QB_RESPONSES.fetch(:user))

  user = stub(Requests, :request, mock_response) do
    stub(qb, :session_token, "token") { qb.get_user(id: 900) }
  end

  assert user
  assert_equal Quickblox::Models::User, user.class
  assert_equal 900, user.id
  assert_equal "mister@one.com", user.email
  assert_equal "Mr One", user.full_name
  assert_equal "1133445566", user.phone
  assert_equal "One", user.login
end

test "#chat_transcript" do
  qb = Quickblox::API.new(
    auth_key: "AUTH_KEY",
    auth_secret: "AUTH_SECRET",
    application_id: 1234,
    email: "account@owner.com",
    password: "foobarbaz"
  )

  mock_response = Requests::Response.new(200, {}, QB_RESPONSES.fetch(:messages))

  mock_user = Quickblox::Models::User.new(
    id: 12243767,
    email: "bar@foo.com",
    full_name: "User",
  )

  chat = stub(Requests, :request, mock_response) do
    stub(qb, :find_user,  mock_user) do
      stub(qb, :session_token, "token") { qb.chat_transcript(dialog_id: "5727676fa28f9a49") }
    end
  end

  assert chat
  assert_equal Quickblox::Models::Chat, chat.class
  assert_equal mock_user, chat.buyer
  assert_equal mock_user, chat.seller
  assert_equal 1, chat.messages.size

  message = chat.messages.first
  assert message
  assert_equal Quickblox::Models::Message, message.class
  assert_equal mock_user, message.sender
end

