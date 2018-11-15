module WillowSword
  module MultipartDeposit

    private
    def multipart_not_supported
      message = 'Server does not support multipart/related content types'
      @error = WillowSword::Error.new(message, :method_not_allowed)
      false
    end

    def validate_multi_part
      true
    end

  end
end
