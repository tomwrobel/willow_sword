module WillowSword
  module Hyrax
    module CollectionsBehavior
      extend ActiveSupport::Concern
      def show
        @collection = Collection.find(params[:id])
        @works = []
        @works = @collection.works if @collection.present?
      end
    end
  end
end
