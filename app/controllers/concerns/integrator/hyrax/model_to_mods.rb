module Integrator
  module Hyrax
    module ModelToMods
      def assign_model_to_mods
        @mapped_metadata = @object.attributes
        @mapped_metadata
      end
    end
  end
end
