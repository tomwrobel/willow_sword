module Integrator
  module Hyrax
    module ServiceDocumentsBehavior
      extend ActiveSupport::Concern
      def show
        @collections = Collection.all
        if @collections.blank?
          @collections = [Collection.new(WillowSword.config.default_collection)]
        end
      end
    end
  end
end
