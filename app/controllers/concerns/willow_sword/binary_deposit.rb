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
      @dir = nil
      if request.body.length > 0
        @dir = File.join('tmp/data', SecureRandom.uuid)
        unless File.directory?(@dir)
          FileUtils.mkdir_p(@dir)
        end
        @file = File.open(File.join(@dir, @filename), 'wb')
        @file.write(request.body.read)
        @file.close
        puts "File path: #{@file.path}"
        # @file.unlink
      end
    end

  end
end
