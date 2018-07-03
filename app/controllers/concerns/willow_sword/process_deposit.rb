# require 'rack/mime'
module WillowSword
  module ProcessDeposit

    private

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
        @file = File.open(File.join(@dir, @headers[:filename]), 'wb')
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

    def fetch_data_content_type
      @data_content_type = nil
      # return unless (@file.present? and File.exist? @file.path)
      # @data_content_type = `file --b --mime-type "#{File.join(Dir.pwd, @file.path)}"`.strip
      @data_content_type = `file --b --mime-type "#{@file.path}"`.strip
      puts "Mime type: #{@data_content_type}"
      # @extension = Rack::Mime::MIME_TYPES.invert[mime_type]
      # Not matching content_type and packaging from headers with that computed.
    end

    def process_data
      # process the saved data
      case @data_content_type
      when 'application/zip'
        # process zip
        puts 'process zip'
        process_zip
        true
      when 'application/xml'
        # process xml
        puts 'process xml'
        # TODO: crosswalk metadata
        # TODO: Add to Hyrax
        true
      else
        puts 'Unknown format of data'
        message = "Server does not support the content type #{@data_content_type}"
        @error = WillowSword::Error.new(message, type = :method_not_allowed)
        false
      end
    end

    def process_zip
      contents_path = File.join(@dir, 'contents')
      bag_path = File.join(@dir, 'bag')
      # unzip file
      zp = WillowSword::ZipPackage.new(@file.path, contents_path)
      zp.unzip_file
      # validate or create bag
      bag = WillowSword::BagPackage.new(contents_path, bag_path)
      @files = bag.package.bag_files - [File.join(bag.package.data_dir, 'metadata.xml')]
      # Extract metadata
      xw = WillowSword::DcCrosswalk.new(File.join(bag.package.data_dir, 'metadata.xml'))
      @attributes = xw.metadata
      puts @attributes
      puts '-'*50
      puts @files
      puts '-'*50
    end

  end
end
