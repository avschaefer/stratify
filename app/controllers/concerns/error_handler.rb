# frozen_string_literal: true

# Concern for handling errors in controllers
module ErrorHandler
  extend ActiveSupport::Concern
  
  included do
    rescue_from FinancialCalculationError, with: :handle_financial_calculation_error
    rescue_from InvalidInputError, with: :handle_invalid_input_error
    rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
  end
  
  private
  
  def handle_financial_calculation_error(error)
    Rails.logger.error "Financial calculation error: #{error.message}"
    Rails.logger.error error.backtrace.join("\n") if error.backtrace
    
    respond_to do |format|
      format.html do
        redirect_back(fallback_location: root_path, alert: "Calculation error: #{error.message}")
      end
      format.json do
        render json: {
          error: error.message,
          context: error.context
        }, status: :unprocessable_entity
      end
    end
  end
  
  def handle_invalid_input_error(error)
    Rails.logger.error "Invalid input error: #{error.message}"
    
    respond_to do |format|
      format.html do
        redirect_back(fallback_location: root_path, alert: "Invalid input: #{error.message}")
      end
      format.json do
        render json: {
          error: error.message,
          field: error.field,
          value: error.value
        }, status: :bad_request
      end
    end
  end
  
  def handle_record_not_found(error)
    Rails.logger.error "Record not found: #{error.message}"
    
    respond_to do |format|
      format.html do
        redirect_back(fallback_location: root_path, alert: 'Record not found.')
      end
      format.json do
        render json: {
          error: 'Record not found'
        }, status: :not_found
      end
    end
  end
end

