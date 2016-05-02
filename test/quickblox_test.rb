require "cutest"
require "mocoso"
require_relative "../lib/quickblox"

include Mocoso

scope "initialization" do
  test "with application credentials" do
    qb = Quickblox.new(
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
    qb = Quickblox.new(
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

test "create session" do
  qb = Quickblox.new(
    auth_key: "AUTH_KEY",
    auth_secret: "AUTH_SECRET",
    application_id: 1234,
    email: "account@owner.com",
    password: "foobarbaz"
  )

  # This is a real life example of a response to POST /session.json
  mock_response = Requests::Response.new(
    201,
    {
      "access-control-allow-origin"=>["*"],
      "cache-control"=>["max-age=0, private, must-revalidate"],
      "content-type"=>["application/json; charset=utf-8"],
      "date"=>["Mon, 02 May 2016 17:52:01 GMT"],
      "etag"=>["\"442ceb087b8b83fee1ba7f28e082caca\""],
      "qb-token-expirationdate"=>["2016-05-02 19:52:00 UTC"],
      "quickblox-rest-api-version"=>["0.1.1"],
      "server"=>["nginx/1.8.1"],
      "status"=>["201 Created"],
      "strict-transport-security"=>["max-age=15768000;"],
      "x-rack-cache"=>["invalidate, pass"],
      "x-request-id"=>["2d7b3f554389b95e8561d89fc77104bd"],
      "x-runtime"=>["0.014038"],
      "x-ua-compatible"=>["IE=Edge,chrome=1"],
      "content-length"=>["259"],
      "connection"=>["keep-alive"]
    },
    "{\"session\":{\"_id\":\"572793c0a28f9a658800002a\",\"application_id\":35265,\"created_at\":\"2016-05-02T17:52:00Z\",\"device_id\":0,\"nonce\":29601,\"token\":\"le-token-stuff\",\"ts\":1462211496,\"updated_at\":\"2016-05-02T17:52:00Z\",\"user_id\":0,\"id\":18862}}"
  )

  assert qb.session.nil?

  stub(Requests, :request, mock_response) { qb.create_session }

  assert qb.session
  assert_equal "le-token-stuff", qb.session.fetch("token")
end

