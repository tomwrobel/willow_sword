module WillowSword
  module ProcessRequest
    extend ActiveSupport::Concern
    include WillowSword::MultipartDeposit
    include WillowSword::AtomEntryDeposit
    include WillowSword::BinaryDeposit
    include WillowSword::SaveData
    include WillowSword::ExtractMetadata

    def validate_and_save_request
      # Choose based on content type
      return false unless validate_target_user
      case request.content_type
      when 'multipart/form-data'
        # multipart deposit
        return false unless validate_multi_part
        return false unless save_multipart_data
      when 'application/atom+xml;type=entry', 'application/xml', 'text/xml'
        # xml deposit
        return false unless validate_atom_entry
        return false unless save_binary_data
      else
        # binary deposit
        return false unless validate_binary_deposit
        return false unless save_binary_data
      end
      if @file.present?
        return false unless File.file?(@file) and validate_payload
      end
      bag_request
      true
      # process_deposit
    end

    def validate_payload
      return true if @headers[:md5hash].nil?
      md5 = `md5sum "#{@file.path}" | awk '{ print $1 }'`.strip
      if md5 == @headers[:md5hash]
        true
      else
        message = "The checksum does not match the header md5 checksum"
        @error = WillowSword::Error.new(message, :checksum_mismatch)
        false
      end
    end

    def bag_request
      # The data is processed as a bag
      # metadata.xml is the metadata file
      contents_path = File.join(@dir, 'contents')
      bag_path = File.join(@dir, 'bag')
      # validate or create bag
      bag = WillowSword::BagPackage.new(contents_path, bag_path)
      @metadata_file = File.join(bag.package.data_dir, 'metadata.xml')
      @files = bag.package.bag_files - [@metadata_file]
    end

    def parse_metadata(file_path, type, required=true)
      if ['work', 'fileset'].include? type
        extract_metadata(file_path, type)
      else
        message = "Unknown type #{type} to extract metadata. has to be work or fileset"
        @error = WillowSword::Error.new(message)
        return false
      end
      return true unless required
      # set default attribute for fileset if none
      @attributes = { 'file_name' => @headers[:filename] } if @attributes.blank? and type == 'fileset'
      @attributes = { 'file_name' => @headers[:filename] } if @attributes['file_name'] == nil and type == 'fileset'

      # metadata should exist
      if @attributes.blank?
        message = "Could not extract any metadata"
        @error = WillowSword::Error.new(message)
        return false
      end
      set_id_from_header
      true
    end

    def set_id_from_header
      unless @headers[:slug].blank?
        @attributes['id'] = @headers[:slug]
      end
    end

  end
end
