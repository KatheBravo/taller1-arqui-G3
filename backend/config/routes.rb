Rails.application.routes.draw do
  # Endpoint WebSocket de ActionCable
  mount ActionCable.server => "/cable"

  # Healthcheck
  get "/health", to: proc { [200, { "Content-Type" => "application/json" }, ['{"status":"ok"}']] }

  # API de Votaciones
  resources :polls, only: [:index, :show] do
    post :vote, on: :member
    post :reset, on: :member
  end
end
