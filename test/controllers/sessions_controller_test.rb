require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "GET /login renders login page" do
    get login_path
    assert_response :success
    assert_select "input[name='email']"
    assert_select "input[name='password']"
  end

  test "POST /login with valid credentials logs in and redirects to root" do
    post login_path, params: { email: "alice@example.com", password: "password123" }
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "POST /login with invalid password renders login with 422" do
    post login_path, params: { email: "alice@example.com", password: "wrong" }
    assert_response :unprocessable_entity
    assert_select "input[name='email']"
  end

  test "POST /login with unknown email renders login with 422" do
    post login_path, params: { email: "nobody@example.com", password: "password123" }
    assert_response :unprocessable_entity
  end

  test "DELETE /logout clears session and redirects to login" do
    post login_path, params: { email: "alice@example.com", password: "password123" }
    delete logout_path
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
  end

  test "authenticated user visiting /login is still shown the login page" do
    post login_path, params: { email: "alice@example.com", password: "password123" }
    get login_path
    assert_response :success
  end

  test "unauthenticated request to dashboard redirects to login" do
    get root_path
    assert_redirected_to login_path
  end
end
