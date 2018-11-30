module WillowSword
  module ExtractMetadata
    extend ActiveSupport::Concern
    include WillowSword::Integrator::ModsToModel

    def extract_metadata(file_path)
      @attributes = nil
      if WillowSword.config.xml_mapping_create == 'MODS'
        xw = WillowSword::ModsCrosswalk.new(file_path, @headers)
        xw.map_xml
        @metadata = xw.metadata
        @mapped_metadata = {}
        assign_mods_to_model
        @attributes = @mapped_metadata
      else
        xw = WillowSword::DcCrosswalk.new(file_path)
        xw.map_xml
        @attributes = xw.metadata
      end
      @resource_type = xw.model if @attributes.any?
    end

  end
end
