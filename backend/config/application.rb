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

    # Rails 7 autocarga automaticamente todo lo contenido en app/
    # (app/core/... -> Core::... y app/infrastructure/... -> Infrastructure::...)
  end
end
