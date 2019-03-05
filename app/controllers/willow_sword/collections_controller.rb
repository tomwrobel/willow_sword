require_dependency "willow_sword/application_controller"

module WillowSword
  class CollectionsController < ApplicationController
    include WillowSword::CollectionsBehavior
  end
end
