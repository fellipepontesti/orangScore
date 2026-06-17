require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    @common_user = users(:two)
  end

  test "should get root when signed in" do
    sign_in @common_user
    get authenticated_root_url
    assert_response :success
  end

  test "should redirect to login when accessing artilharia not signed in" do
    get dashboard_artilharia_url
    assert_redirected_to new_user_session_url
  end

  test "admin (root) can access artilharia" do
    sign_in @admin
    get dashboard_artilharia_url
    assert_response :success
  end

  test "common user cannot access artilharia" do
    sign_in @common_user
    get dashboard_artilharia_url
    assert_response :redirect
  end
end
