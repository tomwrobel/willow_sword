require_dependency "willow_sword/application_controller"

module WillowSword
  class ServiceDocumentsController < ApplicationController

    def show
      @collections = Collection.ordered
    end

  end
end
