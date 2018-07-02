module WillowSword
  module BinaryDeposit

    private

    def validate_binary_deposit
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
      end
      if @file.present? and File.exist? @file.path
        puts "File exists: #{@file.present? and File.exist? @file.path}"
        true
      else
        message = "Content not received"
        @error = WillowSword::Error.new(message, type = :content)
        false
      end
    end

    def validate_binary_data
      return true if @headers[:md5hash].nil?
      # return true unless (@file.present? and File.exist? @file.path)
      # Digest md5 sum isn't same as md5sum
      # require 'digest/md5'
      # md5 = Digest::MD5.new
      # request.body.each { |line| md5.update(line) }
      md5 = `md5sum "#{@file.path}" | awk '{ print $1 }'`.strip
      if md5 == @headers[:md5hash]
        true
      else
        message = "The checksum does not match the header md5 checksum"
        @error = WillowSword::Error.new(message, type = :checksum_mismatch)
        false
      end
    end

  end
end
