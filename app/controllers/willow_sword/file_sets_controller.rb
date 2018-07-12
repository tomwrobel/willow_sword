require_dependency "willow_sword/application_controller"

module WillowSword
  class FileSetsController < ApplicationController
    attr_reader :collection_id, :work_id, :file_set, :object, :headers, :file, :dir, :data_content_type, :attributes, :files, :klass
    include WillowSword::FetchHeaders
    include WillowSword::ProcessDeposit
    include Integrator::Hyrax::WorksBehavior
    include Integrator::Hyrax::FileSetsBehavior

    def show
      @collection_id = params[:collection_id]
      @work_id = params[:work_id]
      @file_set = FileSet.find(params[:id]) if FileSet.exists?(params[:id])
      unless @file_set
        message = "Server cannot find file set with id #{params[:id]}"
        @error = WillowSword::Error.new(message, type = :bad_request)
        render '/willow_sword/shared/error.xml.builder', formats: [:xml], status: @error.code
      end
    end

    def create
      @collection_id = params[:collection_id]
      @work_id = params[:work_id]
      if fetch_and_add_file
        puts "URL #{collection_work_url(params[:collection_id], @object)}"
        render 'create.xml.builder', formats: [:xml], status: 200
      else
        render '/willow_sword/shared/error.xml.builder', formats: [:xml], status: @error.code
      end
    end

    def update
      @collection_id = params[:collection_id]
      @work_id = params[:work_id]
      if fetch_and_add_metadata
        render status: 200
      else
        render '/willow_sword/shared/error.xml.builder', formats: [:xml], status: @error.code
      end
    end

    private
      def fetch_and_add_file
        fetch_headers
        return false unless save_binary_data
        return false unless validate_binary_data
        process_file
        upload_files
        @klass = Work
        @object = klass.find(params[:work_id]) if klass.exists?(params[:work_id])
        if @object
          update_work
        end
        true
      end

      def fetch_and_add_metadata
        fetch_headers
        return false unless save_binary_data
        return false unless validate_binary_data
        fetch_data_content_type
        return false unless process_metadata
        unless params[:id]
          message = "Missing identifier: Unable to search for existing file set without the ID"
          @error = WillowSword::Error.new(message, type = :default)
          return false
        end
        @file_set = find_file_set
        unless @file_set
          message = "Missing file set: Unable to search for existing file set with the ID #{params[:id]}"
          @error = WillowSword::Error.new(message, type = :default)
          return false
        end
        update_file_set
        true
      end


  end
end
