require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module FinancialPlanner
  class Application < Rails::Application
    config.load_defaults 7.1
    config.autoload_lib(ignore: %w(assets tasks))
    
    # Don't require encrypted credentials for development
    config.require_master_key = false if Rails.env.development?
  end
end
