WillowSword::Engine.routes.draw do
  get '/service_document', to: 'service_document#index', defaults: {format: 'xml'}

end
