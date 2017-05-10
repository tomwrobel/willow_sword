module WillowSword
  class Engine < ::Rails::Engine
    isolate_namespace WillowSword
    config.generators.api_only = true
  end
end
