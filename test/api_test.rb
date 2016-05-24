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
  assert_equal ["tag1", "tag2"], user.tags
  assert user.custom_data.nil?
end

test "#get_dialog" do
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

test "#get_messages" do
  qb = Quickblox::API.new(
    auth_key: "AUTH_KEY",
    auth_secret: "AUTH_SECRET",
    application_id: 1234,
    email: "account@owner.com",
    password: "foobarbaz"
  )

  mock_response = Requests::Response.new(200, {}, QB_RESPONSES.fetch(:messages))

  messages = stub(Requests, :request, mock_response) do
    stub(qb, :session_token, "token") { qb.get_messages(dialog_id: "571f8230a0eb478939000052") }
  end

  assert messages
  assert_equal Array, messages.class
  assert messages.size > 0

  message = messages.first
  assert_equal Quickblox::Models::Message, message.class
  assert_equal DateTime.parse("2016-04-26T14:58:59Z"), message.created_at
  assert_equal "yo", message.text
  assert_equal "571f8230a0eb478939000052", message.dialog_id
  assert_equal 12057184, message.sender_id
end

test "#chat_transcript" do
  qb = Quickblox::API.new(
    auth_key: "AUTH_KEY",
    auth_secret: "AUTH_SECRET",
    application_id: 1234,
    email: "account@owner.com",
    password: "foobarbaz"
  )

  mock_messages = [
    Quickblox::Models::Message.new(created_at: "2016-04-26T14:58:59Z", text: "yo", dialog_id: "le-dialog-id", sender_id: 123),
    Quickblox::Models::Message.new(created_at: "2016-04-26T14:59:59Z", text: "hey", dialog_id: "le-dialog-id", sender_id: 123)
  ]
  mock_occupant = Quickblox::Models::User.new(id: 123, full_name: "Me")

  chat = stub(qb, :get_messages, mock_messages) do
    stub(qb, :get_user, mock_occupant) { qb.chat_transcript(dialog_id: "5727676fa28f9a49") }
  end

  assert chat
  assert_equal Quickblox::Models::Chat, chat.class
  assert_equal mock_messages, chat.messages
  assert_equal mock_occupant, chat.occupants.first
  assert chat.dialog.nil?

  assert_equal mock_occupant, chat.messages.first.sender
end

test "#chat_transcripts" do
  qb = Quickblox::API.new(
    auth_key: "AUTH_KEY",
    auth_secret: "AUTH_SECRET",
    application_id: 1234,
    email: "account@owner.com",
    password: "foobarbaz"
  )

  mock_messages = [
    Quickblox::Models::Message.new(created_at: "2016-04-26T14:58:59Z", text: "yo", dialog_id: "le-dialog-id", sender_id: 123),
    Quickblox::Models::Message.new(created_at: "2016-04-26T14:59:59Z", text: "hey", dialog_id: "le-dialog-id", sender_id: 123)
  ]
  mock_occupant = Quickblox::Models::User.new(id: 123, full_name: "Me")

  dialog = Quickblox::Models::Dialog.new(id: "le-dialog-id", occupants_ids: [123, 123], type: 3, created_at: "2016-05-02T17:52:00Z", updated_at: "2016-05-02T17:52:00Z")

  chats = stub(qb, :get_messages, mock_messages) do
    stub(qb, :get_user, mock_occupant) { qb.chat_transcripts(dialogs: [dialog]) }
  end

  assert ! chats.empty?
  chat = chats.first

  assert_equal Quickblox::Models::Chat, chat.class
  assert_equal dialog, chat.dialog
  assert_equal mock_messages, chat.messages
  assert_equal mock_occupant, chat.occupants.first
  assert_equal mock_occupant, chat.messages.first.sender
end

