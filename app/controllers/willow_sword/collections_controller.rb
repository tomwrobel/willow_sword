require_dependency "willow_sword/application_controller"

module WillowSword
  class CollectionsController < ApplicationController

    def show
      @collection = Collection.find(params[:id])
      @works = @collection.works
    end
  end
end
