require_dependency "willow_sword/application_controller"

module WillowSword
  class ServiceDocumentsController < ApplicationController
    include WillowSword::ServiceDocumentsBehavior
  end
end
