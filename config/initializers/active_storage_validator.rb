# frozen_string_literal: true

# Initializer to validate Active Storage S3 configuration in production
# Runs on application startup to catch configuration errors early

if Rails.env.production?
  Rails.application.config.after_initialize do
    if Rails.application.config.active_storage.service == :amazon
      required_vars = %w[AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_S3_BUCKET]
      missing_vars = required_vars.select { |var| ENV[var].blank? }
      
      if missing_vars.any?
        Rails.logger.error("=" * 80)
        Rails.logger.error("ACTIVE STORAGE S3 CONFIGURATION ERROR")
        Rails.logger.error("=" * 80)
        Rails.logger.error("Missing required environment variables: #{missing_vars.join(', ')}")
        Rails.logger.error("")
        Rails.logger.error("Please set the following environment variables:")
        Rails.logger.error("  - AWS_ACCESS_KEY_ID")
        Rails.logger.error("  - AWS_SECRET_ACCESS_KEY")
        Rails.logger.error("  - AWS_REGION (optional, defaults to us-east-1)")
        Rails.logger.error("  - AWS_S3_BUCKET")
        Rails.logger.error("")
        Rails.logger.error("See S3_SETUP.md for detailed setup instructions.")
        Rails.logger.error("=" * 80)
        
        # Don't raise in production - allow app to start but log the error
        # This allows you to fix the issue without downtime
      else
        Rails.logger.info("Active Storage S3 configuration validated successfully")
        Rails.logger.info("S3 Bucket: #{ENV['AWS_S3_BUCKET']}")
        Rails.logger.info("AWS Region: #{ENV['AWS_REGION'] || 'us-east-1'}")
      end
    end
  end
end

