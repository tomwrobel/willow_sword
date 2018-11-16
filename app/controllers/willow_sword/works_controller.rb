require_dependency "willow_sword/application_controller"

module WillowSword
  class WorksController < ApplicationController
    before_action :set_work_klass
    attr_reader :collection_id, :headers, :file, :dir, :data_content_type, :attributes,
      :files, :object, :file_ids, :work_klass, :current_user, :resource_type
    include WillowSword::FetchData
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
      if validate_request
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
      if validate_request
        render 'update.xml.builder', formats: [:xml], status: :no_content
      else
        @error = WillowSword::Error.new("Error updating work") unless @error.present?
        render '/willow_sword/shared/error.xml.builder', formats: [:xml], status: @error.code
      end
    end

    private

    def validate_request
      # Choose based on content type
      return false unless validate_target_user
      case request.content_type
      when 'multipart/form-data'
        # multipart deposit
        return false unless validate_multi_part
        return false unless save_multipart_data
      when 'application/atom+xml;type=entry', 'application/xml', 'text/xml'
        # xml deposit
        return false unless validate_atom_entry
        return false unless save_binary_data
      else
        # binary deposit
        return false unless validate_binary_deposit
        return false unless save_binary_data
      end
      process_deposit
    end

    def process_deposit
      if @file.present?
        return false unless File.file?(@file) and validate_payload
      end
      return false unless process_bag
      set_work_klass # to use class from resource type
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
