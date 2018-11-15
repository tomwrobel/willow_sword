module WillowSword
  module ExtractMetadata

    def extract_metadata
      if WillowSword.config.xml_mapping_create == 'MODS'
        include Integrator::Hyrax::ModsToModel
        xw = WillowSword::ModsCrosswalk.new(file_path)
        xw.map_xml
        assign_mods_to_model
        @attributes = xw.mapped_metadata
      else
        xw = WillowSword::DcCrosswalk.new(file_path)
        xw.map_xml
        @attributes = xw.metadata
      end
    end

  end
end
