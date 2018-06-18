require_dependency "willow_sword/application_controller"

module WillowSword
  class WorksController < ApplicationController
    include WillowSword::FetchHeaders
    include WillowSword::MultipartDeposit
    include WillowSword::AtomEntryDeposit
    include WillowSword::BinaryDeposit
    include WillowSword::ProcessDeposit

    def show
      @work = nil
    end

    def create
      if validate_request
        render json: nil, status: :created, location: collection_work_url(params[:collection_id], 'new_id')
      else
        render '/willow_sword/shared/error.xml.builder', formats: [:xml], status: @error.code
      end
    end

    private

    def validate_request
      fetch_headers
      # Choose based on content type
      case request.content_type
      when 'multipart/related'
        multipart_not_supported
      when 'application/atom+xml;type=entry'
        atom_entry_not_supported
      else
        return false unless validate_deposit
        return false unless save_binary_data
        return false unless validate_data
        fetch_data_content_type
        process_data
      end
    end

  end
end
