module WillowSword
  class Engine < ::Rails::Engine
    isolate_namespace WillowSword
    config.generators.api_only = true
  end

  def self.setup(&block)
    @config ||= WillowSword::Engine::Configuration.new
    yield @config if block
    @config
  end

  def self.config
    Rails.application.config
  end
end
