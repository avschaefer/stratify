# frozen_string_literal: true

# Concern for controllers that handle financial calculations
module Calculatable
  extend ActiveSupport::Concern
  
  # Handle calculation errors gracefully
  def handle_calculation_error(error)
    Rails.logger.error "Calculation error: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    
    render json: { 
      error: 'An error occurred during calculation',
      message: error.message
    }, status: :internal_server_error
  end
end

