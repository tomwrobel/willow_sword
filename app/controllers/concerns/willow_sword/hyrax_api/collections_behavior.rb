module WillowSword
  module HyraxApi
    module CollectionsBehavior
      extend ActiveSupport::Concern
      def show
        @collection = []
        @works = []
      end
    end
  end
end
