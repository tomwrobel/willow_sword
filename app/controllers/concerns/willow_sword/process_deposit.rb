# require 'rack/mime'
require 'fileutils'

module WillowSword
  module ProcessDeposit

    private

    def save_multipart_data
      @file = nil
      @dir = nil
      @dir = File.join('tmp/data', SecureRandom.uuid)
      contents_path = File.join(@dir, 'contents')
      if params[:metadata] || params[:payload]
        unless File.directory?(contents_path)
          FileUtils.mkdir_p(contents_path)
        end
      end
      if params[:metadata]
        # save metadata - params[:metadata]
        path = File.join(contents_path, 'metadata.xml')
        if params[:metadata].kind_of? ActionDispatch::Http::UploadedFile
          tmp = params[:metadata].tempfile
          FileUtils.move tmp.path, path
        else
          File.open(path, 'wb') do |f|
            f.write(params[:metadata])
          end
        end
      end
      if params[:payload]
        # Save payload - params[:payload]
        path = File.join(@dir, params[:payload].original_filename)
        tmp = params[:payload].tempfile
        FileUtils.move tmp.path, path
        @file = File.new(path)
        fetch_data_content_type
        if @data_content_type == 'application/zip'
          # unzip file
          zp = WillowSword::ZipPackage.new(@file.path, contents_path)
          zp.unzip_file
        else
          # Copy file to contents dir
          new_file_path = File.join(contents_path, params[:payload].original_filename)
          FileUtils.cp(@file.path, new_file_path)
        end
      end
      if Dir.empty?(contents_path)
        message = "Content not received"
        @error = WillowSword::Error.new(message, type = :bad_request)
        false
      else
        true
      end
    end

    def save_binary_data
      @file = nil
      @dir = nil
      if request.body.size > 0
        @dir = File.join('tmp/data', SecureRandom.uuid)
        unless File.directory?(@dir)
          FileUtils.mkdir_p(@dir)
        end
        @file = File.open(File.join(@dir, @headers[:filename]), 'wb')
        # @file.write(request.body.read)
        request.body.each { |line| @file.write(line) }
        @file.close
        # @file.unlink
      end
      if @file.present? and File.exist? @file.path
        true
      else
        message = "Content not received"
        @error = WillowSword::Error.new(message, type = :bad_request)
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
      # @extension = Rack::Mime::MIME_TYPES.invert[mime_type]
      # Not matching content_type and packaging from headers with that computed.
    end

    def process_data
      # process the saved data
      case @data_content_type
      when 'application/zip'
        # process zip
        process_zip
      when 'application/xml', 'text/xml'
        # process xml
        @files = []
        process_xml(@file.path)
      else
        message = "Server does not support the content type #{@data_content_type}"
        @error = WillowSword::Error.new(message, type = :content)
        false
      end
    end

    def process_xml(file_path)
      if WillowSword.config.xml_mapping_create == 'MODS'
        xw = WillowSword::ModsCrosswalk.new(file_path)
        xw.map_xml
        @attributes = xw.mapped_metadata
      else
        xw = WillowSword::DcCrosswalk.new(file_path)
        xw.map_xml
        @attributes = xw.metadata
      end
      return true unless @object.blank? # updates to the object
      # new object
      unless @attributes.any?
        message = "Could not extract any metadata"
        @error = WillowSword::Error.new(message, type = :bad_request)
        false
      else
        @resource_type = xw.model
        set_work_klass
        set_id_from_header
        true
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
      metadata_file = File.join(bag.package.data_dir, 'metadata.xml')
      @files = bag.package.bag_files - [metadata_file]
      # Extract metadata
      process_xml(metadata_file)
    end

    def process_file
      @files = [@file.path]
      @attributes = {}
    end

    def process_metadata
      case @data_content_type
      when 'application/xml'
        # process xml
        @files = []
        process_xml(@file.path)
      else
        message = "Server does not support the content type #{@data_content_type}"
        @error = WillowSword::Error.new(message, type = :content)
        false
      end
    end

    def process_bag
      contents_path = File.join(@dir, 'contents')
      bag_path = File.join(@dir, 'bag')
      # validate or create bag
      bag = WillowSword::BagPackage.new(contents_path, bag_path)
      metadata_file = File.join(bag.package.data_dir, 'metadata.xml')
      @files = bag.package.bag_files - [metadata_file]
      # Extract metadata
      process_xml(metadata_file)
    end

    def set_id_from_header
      unless @headers[:slug].blank?
        @attributes['id'] = @headers[:slug]
      end
    end

  end
end
