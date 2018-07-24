require 'fileutils'

module WillowSword
  module FetchHeaders

    private

    def fetch_headers
      @headers = {}
      fetch_content_type
      fetch_filename
      fetch_md5hash
      fetch_packaging
      fetch_in_progress
      fetch_on_behalf_of
      fetch_slug
      fetch_hyrax_work_model
    end

    def fetch_content_type
      @headers[:content_type] = request.headers.fetch('Content-Type', nil)
      # puts "Content type: #{@headers[:content_type]}"
    end

    def fetch_filename
      @headers[:filename] = nil
      cd = request.headers.fetch('Content-Disposition', '')
      if cd.include? '='
        @headers[:filename] = cd.split('=')[-1].strip()
      end
      if @headers[:filename].blank?
        @headers[:filename] = SecureRandom.uuid
      end
      # puts "Filename: #{@headers[:filename]}"
    end

    def fetch_md5hash
      @headers[:md5hash] = request.headers.fetch('Content-MD5', nil)
      # puts "MD5 hash: #{@headers[:md5hash]}"
    end

    def fetch_packaging
      @headers[:packaging] = request.headers.fetch('Packaging', nil)
      # puts "Packaging #{@headers[:packaging]}"
    end

    def fetch_in_progress
      @headers[:in_progress] = request.headers.fetch('In-Progress', nil)
      # puts "In progress: #{@headers[:in_progress]}"
    end

    def fetch_on_behalf_of
      @headers[:on_behalf_of] = request.headers.fetch('On-Behalf-Of', nil)
      # puts "On behalf of: #{@headers[:on_behalf_of]}"
    end

    def fetch_slug
      @headers[:slug] = request.headers.fetch('Slug', nil)
      # puts "Slug: #{@headers[:slug]}"
    end
    
    # @todo add custom header for model HyraxWorkModel
    def fetch_hyrax_work_model
      @headers[:hyrax_work_model] = request.headers.fetch('Hyrax-Work-Model', nil)
    end

  end
end
