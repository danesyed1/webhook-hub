require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "GET /signup renders signup form" do
    get signup_path
    assert_response :success
    assert_select "input[name='user[email]']"
    assert_select "input[name='user[password]']"
  end

  test "POST /signup with valid data creates user, org, membership and redirects" do
    assert_difference([ "User.count", "Organization.count", "Membership.count" ], 1) do
      post signup_path, params: {
        user: {
          name: "New User",
          email: "newuser@example.com",
          password: "secret123",
          password_confirmation: "secret123"
        },
        organization_name: "New Corp"
      }
    end
    assert_response :redirect
    new_user = User.find_by(email: "newuser@example.com")
    assert_not_nil new_user
    assert_equal "New Corp", new_user.organizations.first.name
    assert_equal "owner", new_user.memberships.first.role
  end

  test "POST /signup logs user in after registration" do
    post signup_path, params: {
      user: {
        name: "Auto Login",
        email: "autologin@example.com",
        password: "secret123",
        password_confirmation: "secret123"
      }
    }
    follow_redirect!
    assert_response :success
  end

  test "POST /signup with missing password renders form with 422" do
    assert_no_difference("User.count") do
      post signup_path, params: {
        user: {
          name: "Bad User",
          email: "bad@example.com",
          password: "",
          password_confirmation: ""
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST /signup with mismatched passwords renders form with 422" do
    assert_no_difference("User.count") do
      post signup_path, params: {
        user: {
          name: "Mismatch",
          email: "mismatch@example.com",
          password: "password1",
          password_confirmation: "password2"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST /signup with duplicate email renders form with 422" do
    assert_no_difference("User.count") do
      post signup_path, params: {
        user: {
          name: "Duplicate",
          email: "alice@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_response :unprocessable_entity
  end
end
