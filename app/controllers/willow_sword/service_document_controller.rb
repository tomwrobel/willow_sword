require_dependency "willow_sword/application_controller"

module WillowSword
  class ServiceDocumentController < ApplicationController

    def index
      @collections = Collection.ordered
    end

  end
end
