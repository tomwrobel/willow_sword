module WillowSword
  module ModelToMods
    def assign_model_to_mods
      @mapped_metadata = {}
      # abstract
      @mapped_metadata['abstract'] = Array(@object.fetch(:abstract, ''))
      # accessCondition
      if Array(@object.fetch(:license_and_rights_information)).any?
        @mapped_metadata['accessCondition'] = Array(@object[:license_and_rights_information][0].fetch(:licence, ''))
      end
      # identfier
      @mapped_metadata
    end
  end
end
