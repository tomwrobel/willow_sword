module WillowSword
  class ApplicationController < ActionController::API
    # protect_from_forgery with: :exception
    before_action :fetch_headers, :authorize_request
    include WillowSword::FetchHeaders
    include WillowSword::AuthorizeRequest
  end
end
