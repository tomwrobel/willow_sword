module WillowSword
  module ServiceDocumentsBehavior
    extend ActiveSupport::Concern
    include Integrator::Hyrax::ServiceDocumentsBehavior
  end
end
