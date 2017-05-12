require 'test_helper'

module WillowSword
  class ServiceDocumentsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test "should get show" do
      get service_documents_show_url
      assert_response :success
    end

  end
end
