module WillowSword
  module BinaryDeposit

    private

    def validate_binary
      # Requires no active validation
      true
    end

    def save_binary_data
      puts 'saving body'
      puts request.body.length
      @file = nil
      if request.body.length > 0
        filepath = File.join('tmp/data', SecureRandom.uuid)
        unless File.directory?(filepath)
          FileUtils.mkdir_p(filepath)
        end
        @file = File.open(File.join(filepath, @filename), 'wb')
        @file.write(request.body.read)
        @file.close
        puts "File path: #{@file.path}"
        # @file.unlink 
      end
    end

  end
end
