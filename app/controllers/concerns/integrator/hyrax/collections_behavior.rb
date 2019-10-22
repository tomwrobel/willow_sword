module Integrator
  module Hyrax
    module CollectionsBehavior
      extend ActiveSupport::Concern
      attr_reader :klass, :collection, :works

      def show
        # TODO: Use search query to get 100 most recent list of works
        #       Process current = params[:start]
        #       Need to compute the link for first, last, next and previous searches
        #       https://bitworking.org/projects/atom/rfc5023.html#rfc.section.10.1
        #       first = 0
        #       last = (total_records/100).to_i
        #       previous = (current == 0) ? nil : current - 1
        #       next = (current == last) ? nil : current + 1
        @collection = nil
        @works = []
        if params[:id] == WillowSword.config.default_collection[:id]
          @collection = klass.new(WillowSword.config.default_collection)
          WillowSword.config.work_models.each do |work_model|
            @works += work_model.singularize.classify.constantize.all
          end
        else
          @collection = klass.find(params[:id]) if Collection.exists?(params[:id])
          @works = @collection.works if @collection.present?
        end
        unless @collection
          message = "Server cannot find collection with id #{params[:id]}"
          @error = WillowSword::Error.new(message, :not_found)
          render '/willow_sword/shared/error.xml.builder', formats: [:xml], status: @error.code
          return
        end
      end

      private

      def klass
        WillowSword.config.collection_models.first.singularize.classify.constantize
      end

    end
  end
end
