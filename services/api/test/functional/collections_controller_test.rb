require 'test_helper'

class CollectionsControllerTest < ActionController::TestCase

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:objects)
  end

end