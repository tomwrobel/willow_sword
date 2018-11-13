module WillowSword
  module AuthorizeRequest
    private

    def authorize_request
      @current_user = nil
      return true unless WillowSword.config.authorize_request
      api_key = @headers.fetch(:api_key, nil)
      @current_user = User.find_by(api_key: @headers[:api_key]) unless api_key.blank?
      unless @current_user.present?
        unless api_key.blank?
          message = "Not authorized. API key not found."
        else
          message = "Not authorized. API key not available."
        end
        @error = WillowSword::Error.new(message, type = :target_owner_unknown)
        render '/willow_sword/shared/error.xml.builder', formats: [:xml], status: @error.code
      else
        true
      end
    end

  end
end
