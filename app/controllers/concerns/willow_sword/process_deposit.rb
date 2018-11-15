# require 'rack/mime'
module WillowSword
  module ProcessDeposit

    private

    def validate_payload
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
        @error = WillowSword::Error.new(message, :checksum_mismatch)
        false
      end
    end

    def process_metadata(file_path)
      extract_metadata
      # updates to the object need not have metadata
      return true unless @object.blank?
      # new object
      unless @attributes.any?
        message = "Could not extract any metadata"
        @error = WillowSword::Error.new(message)
        false
      else
        @resource_type = xw.model
        set_id_from_header
        true
      end
    end

    # def process_file
    #   @files = [@file.path]
    #   @attributes = {}
    # end

    # def process_metadata
    #   case @data_content_type
    #   when 'application/xml'
    #     # process xml
    #     @files = []
    #     process_metadata(@file.path)
    #   else
    #     message = "Server does not support the content type #{@data_content_type}"
    #     @error = WillowSword::Error.new(message, content)
    #     false
    #   end
    # end

    def process_bag
      # The data is processed as a bag
      # file called metadata.xml is the metadata file
      contents_path = File.join(@dir, 'contents')
      bag_path = File.join(@dir, 'bag')
      # validate or create bag
      bag = WillowSword::BagPackage.new(contents_path, bag_path)
      metadata_file = File.join(bag.package.data_dir, 'metadata.xml')
      @files = bag.package.bag_files - [metadata_file]
      # Extract metadata
      process_metadata(metadata_file)
    end

    def set_id_from_header
      unless @headers[:slug].blank?
        @attributes['id'] = @headers[:slug]
      end
    end

  end
end
