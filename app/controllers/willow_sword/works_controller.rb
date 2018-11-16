require_dependency "willow_sword/application_controller"

module WillowSword
  class WorksController < ApplicationController
    before_action :set_work_klass
    attr_reader :collection_id, :object, :current_user
    include WillowSword::ProcessRequest
    include WillowSword::Integrator::WorksBehavior
    include WillowSword::Integrator::ModelToMods

    def show
      @collection_id = params[:collection_id]
      find_work_by_query
      render_not_found and return unless @object
      if (WillowSword.config.xml_mapping_read == 'MODS')
        @mods = assign_model_to_mods
        render '/willow_sword/works/show.mods.xml.builder', formats: [:xml], status: 200
      else
        render '/willow_sword/works/show.dc.xml.builder', formats: [:xml], status: 200
      end
    end

    def create
      @error = nil
      if perform_create
        @collection_id = params[:collection_id]
        render 'create.xml.builder', formats: [:xml], status: :created, location: collection_work_url(params[:collection_id], @object)
      else
        @error = WillowSword::Error.new("Error creating work") unless @error.present?
        render '/willow_sword/shared/error.xml.builder', formats: [:xml], status: @error.code
      end
    end

    def update
      @collection_id = params[:collection_id]
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
      return false unless parse_metadata(@metadata_file, true)
      set_work_klass
      upload_files unless @files.blank?
      add_work
      true
    end

    def perform_update
      return false unless validate_and_save_request
      return false unless parse_metadata(@metadata_file, false)
      upload_files unless @files.blank?
      add_work
      true
    end

    def render_not_found
      message = "Server cannot find work with id #{params[:id]}"
      @error = WillowSword::Error.new(message)
      render '/willow_sword/shared/error.xml.builder', formats: [:xml], status: @error.code
    end

  end
end
