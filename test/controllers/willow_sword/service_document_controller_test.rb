require 'test_helper'

module WillowSword
  class ServiceDocumentControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test "should get index" do
      get service_document_index_url
      assert_response :success
    end

  end
end
