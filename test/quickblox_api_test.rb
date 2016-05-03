require "cutest"
require "mocoso"
require "quickblox"
require "date"

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
    "{\"session\":{\"_id\":\"572793c0a28f9a658800002a\",\"application_id\":35265,\"created_at\":\"2016-05-02T17:52:00Z\",\"device_id\":0,\"nonce\":29601,\"token\":\"le-token-stuff\",\"ts\":1462211496,\"updated_at\":\"2016-05-02T17:52:00Z\",\"user_id\":0,\"id\":18862}}"
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

test "#find_user" do
  qb = Quickblox::API.new(
    auth_key: "AUTH_KEY",
    auth_secret: "AUTH_SECRET",
    application_id: 1234,
    email: "account@owner.com",
    password: "foobarbaz"
  )

  mock_response = Requests::Response.new(
    200,
    {},
    "{\"user\":{\"id\":900,\"owner_id\":45,\"full_name\":\"Mr One\",\"email\":\"mister@one.com\",\"login\":\"One\",\"phone\":\"1133445566\",\"website\":null,\"created_at\":\"2016-02-10T12:07:50Z\",\"updated_at\":\"2016-03-16T17:42:27Z\",\"last_request_at\":\"2016-03-17T12:34:00Z\",\"external_user_id\":null,\"facebook_id\":null,\"twitter_id\":null,\"blob_id\":null,\"custom_data\":null,\"twitter_digits_id\":null,\"user_tags\":\"tag1,tag2\"}}"
  )

  user = stub(Requests, :request, mock_response) do
    stub(qb, :session_token, "token") { qb.find_user(user_id: 900) }
  end

  assert user
  assert_equal Quickblox::Models::User, user.class
  assert_equal 900, user.id
  assert_equal "mister@one.com", user.email
  assert_equal "Mr One", user.full_name
  assert_equal "1133445566", user.phone
  assert_equal "One", user.login
end

