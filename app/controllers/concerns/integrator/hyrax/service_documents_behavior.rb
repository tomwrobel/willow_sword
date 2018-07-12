module Integrator
  module Hyrax
    module ServiceDocumentsBehavior
      extend ActiveSupport::Concern
      def show
        @collections = Collection.all
      end
    end
  end
end
