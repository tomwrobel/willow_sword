require 'fileutils'

module WillowSword
  module FetchHeaders

    private

    def fetch_headers
      fetch_content_type
      fetch_filename
      fetch_md5hash
      fetch_packaging
      fetch_in_progress
      fetch_on_behalf_of
      fetch_slug
    end

    def fetch_content_type
      @content_type = request.headers.fetch('Content-Type', nil)
      puts "Content type: #{@content_type}"
    end

    def fetch_filename
      @filename = nil
      cd = request.headers.fetch('Content-Disposition', '')
      if cd.include? '='
        @filename = cd.split('=')[-1].strip()
      end
      if @filename.blank?
        @filename = SecureRandom.uuid
      end
      puts "Filename: #{@filename}"
    end

    def fetch_md5hash
      @md5hash = request.headers.fetch('Content-MD5', nil)
      puts "MD5 hash: #{@md5hash}"
    end

    def fetch_packaging
      @packaging = request.headers.fetch('Packaging', nil)
      puts "Packaging #{@packaging}"
    end

    def fetch_in_progress
      @in_progress = request.headers.fetch('In-Progress', nil)
      puts "In progress: #{@in_progress}"
    end

    def fetch_on_behalf_of
      @on_behalf_of = request.headers.fetch('On-Behalf-Of', nil)
      puts "On behalf of: #{@on_behalf_of}"
    end

    def fetch_slug
      @slug = request.headers.fetch('Slug', nil)
      puts "Slug: #{@slug}"
    end
   
  end
end
