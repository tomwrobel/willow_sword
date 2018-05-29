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
        process_zip
        # TODO: match with content_type and packaging
        # TODO: verify md5 sum
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
        puts 'Unknown format of data'
        message = "Server does not support the content type #{@data_content_type}"
        @error = WillowSword::Error.new(message, type = :method_not_allowed)
        false
      end
    end

    def process_zip
      # unzip file
      contents = File.join(@dir, 'contents')
      zp = WillowSword::ZipPackage.new(@file.path, contents)
      zp.unzip_file
      # validate or create bag
      bag = WillowSword::BagPackage.new(contents, File.join(@dir, 'bag'))
      data_files = bag.package.bag_files - [File.join(bag.package.data_dir, 'envFormat.md')]
      # Extract metadata
      xw = WillowSword::DcCrosswalk.new(File.join(bag.data_dir, 'metadata.xml'))
      metadata = xw.metadata
      puts metadata
      puts '-'*50
      puts data_files
      puts '-'*50
      # create work
      create_work(metadata, data_files)
    end

    def create_work(metadata, data_files)
      puts 'In create work'
      true
    end

  end
end
