# frozen_string_literal: true

# Concern for controllers that handle exports
module Exportable
  extend ActiveSupport::Concern
  
  # Handle export generation errors
  def handle_export_error(error)
    Rails.logger.error "Export error: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    
    redirect_back(fallback_location: root_path, alert: 'An error occurred while generating the export. Please try again.')
  end
end

