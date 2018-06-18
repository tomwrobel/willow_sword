module WillowSword
  module BinaryDeposit

    private

    def validate_deposit
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
        # @file.write(request.body.read)
        request.body.each { |line| @file.write(line) }
        @file.close
        puts "File path: #{@file.path}"
        # @file.unlink
        true
      else
        message = "Content not received"
        @error = WillowSword::Error.new(message, type = :content)
        false
      end
    end

    def validate_data
      return true if @md5hash.nil?
      require 'digest/md5'
      # md5 = Digest::MD5.hexdigest(request.body.read)
      md5 = Digest::MD5.new
      request.body.each { |line| md5.update(line) }
      puts "md5 from data   #{md5.hexdigest}"
      puts "md5 from header #{@md5hash}"
      if md5.hexdigest != @md5hash
        message = "The checksum does not match the header md5 checksum"
        @error = WillowSword::Error.new(message, type = :checksum_mismatch)
        false
      else
        true
      end
    end

  end
end
