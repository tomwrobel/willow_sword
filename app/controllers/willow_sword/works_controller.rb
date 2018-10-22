require_dependency "willow_sword/application_controller"

module WillowSword
  class WorksController < ApplicationController
    before_action :fetch_headers, :set_work_klass
    attr_reader :collection_id, :headers, :file, :dir, :data_content_type, :attributes, :files, :object, :file_ids, :work_klass
    include WillowSword::FetchHeaders
    include WillowSword::MultipartDeposit
    include WillowSword::AtomEntryDeposit
    include WillowSword::BinaryDeposit
    include WillowSword::ProcessDeposit
    include Integrator::Hyrax::WorksBehavior
    include WillowSword::ModelToMods

    def show
      @collection_id = params[:collection_id]
      @object = find_work
      unless @object
        message = "Server cannot find work with id #{params[:id]}"
        @error = WillowSword::Error.new(message, type = :bad_request)
        render '/willow_sword/shared/error.xml.builder', formats: [:xml], status: @error.code
      end
      if (WillowSword.config.xml_mapping_read == 'MODS')
        @mods = assign_model_to_mods
        render '/willow_sword/works/show.mods.xml.builder', formats: [:xml], status: 200
      else
        render '/willow_sword/works/show.dc.xml.builder', formats: [:xml], status: 200
      end
    end

    def create
      if validate_request
        @collection_id = params[:collection_id]
        # puts "URL #{collection_work_url(params[:collection_id], @object)}"
        render 'create.xml.builder', formats: [:xml], status: :created, location: collection_work_url(params[:collection_id], @object)
      else
        render '/willow_sword/shared/error.xml.builder', formats: [:xml], status: @error.code
      end
    end

    private

    def validate_request
      # Choose based on content type
      case request.content_type
      when 'multipart/related'
        multipart_not_supported
        return false
      when 'application/atom+xml;type=entry'
        # atom deposit
        return false unless validate_atom_entry
      else
        # binary deposit
        return false unless validate_binary_deposit
      end
      fetch_data_and_deposit
    end

    private
      def fetch_data_and_deposit
        return false unless save_binary_data
        return false unless validate_binary_data
        fetch_data_content_type
        return false unless process_data
        upload_files unless @files.blank?
        add_work
        true
      end

  end
end
