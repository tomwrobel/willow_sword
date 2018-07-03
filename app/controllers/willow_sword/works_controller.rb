require_dependency "willow_sword/application_controller"

module WillowSword
  class WorksController < ApplicationController
    attr_reader :headers, :file, :dir, :data_content_type, :attributes, :files, :object, :file_ids, :klass
    include WillowSword::FetchHeaders
    include WillowSword::MultipartDeposit
    include WillowSword::AtomEntryDeposit
    include WillowSword::BinaryDeposit
    include WillowSword::ProcessDeposit
    include WillowSword::Hyrax::WorksBehavior

    def show
      @work = nil
    end

    def create
      if validate_request
        puts "URL #{collection_work_url(params[:collection_id], @object)}"
        render json: nil, status: :created, location: collection_work_url(params[:collection_id], @object)
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
        # binary deposit
        return false unless validate_binary_deposit
        return false unless save_binary_data
        return false unless validate_binary_data
        fetch_data_content_type
        process_data
        @klass = Work
        upload_files unless @files.blank?
        add_work
        true
      end
    end

  end
end
