require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
# ActiveRecord omitido intencionalmente para Clean Architecture y persistencia pura en Redis
require "action_controller/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module DecisionRoomBackend
  class Application < Rails::Application
    config.load_defaults 7.1

    # Modo API pura
    config.api_only = true

    # Autocarga de las capas de Clean Architecture
    config.autoload_paths << Rails.root.join("app/core")
    config.autoload_paths << Rails.root.join("app/core/entities")
    config.autoload_paths << Rails.root.join("app/core/use_cases")
    config.autoload_paths << Rails.root.join("app/infrastructure")
    config.autoload_paths << Rails.root.join("app/infrastructure/repositories")
  end
end
