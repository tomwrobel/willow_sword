require_dependency "willow_sword/application_controller"

module WillowSword
  class FileSetsController < ApplicationController
    before_action :set_file_set_klass, :set_work_klass
    attr_reader :collection_id, :work_id, :file_set, :object, :headers, :file, :dir,
                :data_content_type, :attributes, :files, :work_klass, :file_set_klass
    include WillowSword::ProcessDeposit
    include WillowSword::Integrator::WorksBehavior
    include WillowSword::Integrator::FileSetsBehavior

    def show
      @collection_id = params[:collection_id]
      @work_id = params[:work_id]
      @file_set = find_file_set
      unless @file_set
        message = "Server cannot find file set with id #{params[:id]}"
        @error = WillowSword::Error.new(message, type = :bad_request)
        render '/willow_sword/shared/error.xml.builder', formats: [:xml], status: @error.code
        return
      end
    end

    def create
      @collection_id = params[:collection_id]
      @work_id = params[:work_id]
      if fetch_and_add_file
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
        return false unless save_binary_data
        return false unless validate_binary_data
        process_file
        upload_files
        @object = work_klass.find(params[:work_id]) if work_klass.exists?(params[:work_id])
        if @object
          update_work
        end
        true
      end

      def fetch_and_add_metadata
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
