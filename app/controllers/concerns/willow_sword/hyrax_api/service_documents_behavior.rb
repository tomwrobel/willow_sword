module WillowSword
  module HyraxApi
    module ServiceDocumentsBehavior
      extend ActiveSupport::Concern
      def show
        @collections = []
      end
    end
  end
end
