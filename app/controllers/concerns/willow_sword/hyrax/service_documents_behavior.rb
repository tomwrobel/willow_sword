module WillowSword
  module Hyrax
    module ServiceDocumentsBehavior
      extend ActiveSupport::Concern
      def show
        @collections = Collection.ordered
      end
    end
  end
end
