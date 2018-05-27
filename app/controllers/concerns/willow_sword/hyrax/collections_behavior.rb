module WillowSword
  module Hyrax
    module CollectionsBehavior
      extend ActiveSupport::Concern
      def show
        @collection = Collection.find(params[:id])
        @works = @collection.works
      end
    end
  end
end
