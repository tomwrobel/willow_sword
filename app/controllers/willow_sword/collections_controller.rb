require_dependency "willow_sword/application_controller"

module WillowSword
  class CollectionsController < ApplicationController
    before_action :set_klass
    include Integrator::Hyrax::CollectionsBehavior
  end
end
