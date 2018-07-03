require_dependency "willow_sword/application_controller"

module WillowSword
  class FileSetsController < ApplicationController
    attr_reader :collection_id, :object_id, :file_set

    def show
      @collection_id = params[:collection_id]
      @object_id = params[:object_id]
      @file_set = FileSet.find(params[:id])
      unless @file_set
        message = "Server cannot find file set with id #{params[:id]}"
        @error = WillowSword::Error.new(message, type = :bad_request)
        render '/willow_sword/shared/error.xml.builder', formats: [:xml], status: @error.code
      end
    end

  end
end
