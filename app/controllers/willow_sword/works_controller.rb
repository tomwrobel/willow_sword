require_dependency "willow_sword/application_controller"

module WillowSword
  class WorksController < ApplicationController
    def show
      @work = nil
    end

    def create
      # support multiple content-types
      #   application/zip = Resource with a Binary File Deposit
      #   multipart/related = Resource with a Multipart Deposit
      #   application/atom+xml;type=entry = Resource with an Atom Entry
      puts params
      validate_headers
      render json: nil, status: :created, location: collection_work_url(params[:collection_id], 'new_id')
    end

    private
    def validate_headers
      puts request.headers
      puts '-'*50
      # request.headers["Content-disposition"]
      # Choose based on content type
      case request.content_type
      when 'multipart/related'
        validate_multipart
      when 'application/atom+xml;type=entry'
        validate_atom_entry
      else
        validate_default
      end
    end

    def validate_multipart
      puts 'multi-part'
      true
    end

    def validate_atom_entry
      puts 'atom-entry'
      true
    end

    def validate_default
      puts 'default'
      true
    end

  end
end
