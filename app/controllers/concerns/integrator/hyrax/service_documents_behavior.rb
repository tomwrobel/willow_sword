module Integrator
  module Hyrax
    module ServiceDocumentsBehavior
      extend ActiveSupport::Concern
      def show
        @collections = Collection.all
        unless @collections
          @collections = [Collection.new(WillowSword.config.default_collection)]
        end
      end
    end
  end
end
