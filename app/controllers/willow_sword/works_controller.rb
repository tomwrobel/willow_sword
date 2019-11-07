require_dependency "willow_sword/application_controller"

module WillowSword
  class WorksController < ApplicationController
    before_action :set_work_klass
    attr_reader :object, :current_user
    include WillowSword::ProcessRequest
    include WillowSword::WorksBehavior

    def show
      # @collection_id = params[:collection_id]
      begin
        find_work_by_query
        render_not_found and return unless @object
        xw_klass = WillowSword.config.xw_to_xml_for_work
        xw = xw_klass.new(@object).to_xml
        @xml_data = xw.doc.to_s
        render 'show.xml', formats: [:xml], status: 200
      rescue => error
        # If an unspecified error occurs, particularly if
        # XML generation fails, return an empty record
        # This is to aid in Symplectic Harvesting
        Rails.logger.error error.to_s
        Rails.logger.error "Returning empty METS response"
        render_empty_record and return
      end
    end

    def create
      @error = nil
      if perform_create
        # @collection_id = params[:collection_id]
        render 'create.xml.builder', formats: [:xml], status: :created, location: collection_work_url(params[:collection_id], @object)
      else
        @error = WillowSword::Error.new("Error creating work") unless @error.present?
        render '/willow_sword/shared/error.xml.builder', formats: [:xml], status: @error.code
      end
    end

    def update
      # @collection_id = params[:collection_id]
      find_work_by_query
      render_not_found and return unless @object
      @error = nil
      if perform_update
        render 'update.xml.builder', formats: [:xml], status: :no_content
      else
        @error = WillowSword::Error.new("Error updating work") unless @error.present?
        render '/willow_sword/shared/error.xml.builder', formats: [:xml], status: @error.code
      end
    end

    private

    def perform_create
      return false unless validate_and_save_request
      return false unless parse_metadata(@metadata_file, 'work', true)
      set_work_klass
      upload_files unless @files.blank?
      add_work
      upload_files_with_attributes unless @files_attributes.blank?
      true
    end

    def perform_update
      return false unless validate_and_save_request
      return false unless parse_metadata(@metadata_file, 'work', false)
      upload_files unless @files.blank?
      add_work
      upload_files_with_attributes unless @files_attributes.blank?
      true
    end

    def render_not_found
      message = "Server cannot find work with id #{params[:id]}"
      @error = WillowSword::Error.new(message, :not_found)
      render '/willow_sword/shared/error.xml.builder', formats: [:xml], status: @error.code
    end

    def render_empty_record
      # In order to prevent a mass harvest from hanging on any given record, we
      # return a default empty 'success' result
      render file: '/willow_sword/shared/empty_record.xml', formats: [:xml]
    end
  end
end
