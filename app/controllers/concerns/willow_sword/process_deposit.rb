# require 'rack/mime'
module WillowSword
  module ProcessDeposit

    private

    def fetch_data_content_type
      @data_content_type = nil
      puts "File exists: #{@file.present? and File.exist? @file.path}"
      return unless (@file.present? and File.exist? @file.path)
      # @data_content_type = `file --b --mime-type "#{File.join(Dir.pwd, @file.path)}"`.strip
      @data_content_type = `file --b --mime-type "#{@file.path}"`.strip
      puts "Mime type: #{@data_content_type}"
      # @extension = Rack::Mime::MIME_TYPES.invert[mime_type]
    end

    def validate_data
      # Validate against hash
      case @data_content_type
      when 'application/zip'
        # process zip
        puts 'process zip'
        # TODO: match with content_type and packaging
        # TODO: verify md5 sum
        # TODO: Unzip file
        # TODO: validate if it is a bag
        # TODO: crosswalk metadata
        # TODO: Add to Hyrax
        true
      when 'application/xml'
        # process xml
        puts 'process xml'
        # TODO: match with content_type and packaging
        # TODO: verify md5 sum
        # TODO: crosswalk metadata
        # TODO: Add to Hyrax
        true
      else
        puts 'Unknow format of data'
        message = 'Server does not support this content type'
        @error = WillowSword::Error.new(message, type = :method_not_allowed)
        false
      end
    end

  end
end
