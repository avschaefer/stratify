require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module FinancialPlanner
  class Application < Rails::Application
    # Initialize configuration defaults for Rails 8.0
    config.load_defaults 8.0
    config.autoload_lib(ignore: %w(assets tasks))
    
    # Explicitly autoload services from calculations directory
    # Rails 8 with Zeitwerk requires this for nested service directories
    config.autoload_paths += %W(#{config.root}/app/services/calculations)
    
    # Don't require encrypted credentials for development
    config.require_master_key = false if Rails.env.development?
  end
end
