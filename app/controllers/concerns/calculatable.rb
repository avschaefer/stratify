# frozen_string_literal: true

# Concern for controllers that handle financial calculations
module Calculatable
  extend ActiveSupport::Concern
  
  # Handle calculation errors gracefully
  def handle_calculation_error(error)
    Rails.logger.error "Calculation error: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    
    # Include more details in the error response
    error_message = error.message
    if error.respond_to?(:original_error) && error.original_error
      error_message = "#{error.message}: #{error.original_error.message}"
    end
    
    render json: { 
      error: 'An error occurred during calculation',
      message: error_message,
      details: error.class.name
    }, status: :internal_server_error
  end
end

