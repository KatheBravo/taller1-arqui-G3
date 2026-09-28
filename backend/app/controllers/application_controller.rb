class ApplicationController < ActionController::API
  rescue_from Core::Errors::DomainError do |exception|
    render json: {
      error: exception.class.name.demodulize,
      message: exception.message
    }, status: :unprocessable_entity
  end
end
