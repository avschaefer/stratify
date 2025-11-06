# frozen_string_literal: true

# Rake task to test S3 connection and Active Storage functionality
# Usage: rails s3:test

namespace :s3 do
  desc "Test S3 connection and Active Storage configuration"
  task test: :environment do
    puts "=" * 80
    puts "S3 Connection Test"
    puts "=" * 80
    puts ""
    
    # Check Active Storage service
    service = Rails.application.config.active_storage.service
    puts "Active Storage Service: #{service}"
    puts ""
    
    if service == :amazon
      # Check environment variables
      required_vars = {
        'AWS_ACCESS_KEY_ID' => ENV['AWS_ACCESS_KEY_ID'],
        'AWS_SECRET_ACCESS_KEY' => ENV['AWS_SECRET_ACCESS_KEY'],
        'AWS_S3_BUCKET' => ENV['AWS_S3_BUCKET'],
        'AWS_REGION' => ENV['AWS_REGION'] || 'us-east-1'
      }
      
      puts "Environment Variables:"
      required_vars.each do |key, value|
        status = value.present? ? "✓ Set" : "✗ Missing"
        display_value = key == 'AWS_SECRET_ACCESS_KEY' && value.present? ? "[REDACTED]" : value
        puts "  #{key}: #{status} (#{display_value || 'not set'})"
      end
      puts ""
      
      # Check if all required vars are set
      missing = required_vars.select { |_k, v| v.blank? }
      if missing.any?
        puts "ERROR: Missing required environment variables: #{missing.keys.join(', ')}"
        puts "Set these variables and try again."
        exit 1
      end
      
      # Test S3 connection
      begin
        puts "Testing S3 connection..."
        s3_client = Aws::S3::Client.new(
          access_key_id: ENV['AWS_ACCESS_KEY_ID'],
          secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
          region: ENV['AWS_REGION'] || 'us-east-1'
        )
        
        bucket_name = ENV['AWS_S3_BUCKET']
        
        # Try to list bucket contents (this tests connection and permissions)
        puts "Checking bucket access: #{bucket_name}..."
        s3_client.list_objects_v2(bucket: bucket_name, max_keys: 1)
        puts "✓ Bucket access successful"
        puts ""
        
        # Test Active Storage attachment
        puts "Testing Active Storage attachment..."
        test_user = User.first
        
        if test_user.nil?
          puts "⚠ No users found in database. Creating test user..."
          test_user = User.create!(
            email: "test-s3-#{Time.current.to_i}@example.com",
            password: "test123456"
          )
        end
        
        # Create test file
        test_content = "S3 Connection Test - #{Time.current.iso8601}"
        test_file = Tempfile.new(['s3_test', '.txt'])
        test_file.write(test_content)
        test_file.rewind
        
        # Attach file
        filename = "s3_test_#{Time.current.strftime('%Y%m%d_%H%M%S')}.txt"
        test_user.data_files.attach(
          io: test_file,
          filename: filename,
          content_type: 'text/plain'
        )
        test_file.close
        test_file.unlink
        
        attachment = test_user.data_files.last
        
        if attachment.present?
          puts "✓ File uploaded successfully"
          puts "  Filename: #{attachment.filename}"
          puts "  Size: #{attachment.byte_size} bytes"
          puts "  Content Type: #{attachment.content_type}"
          puts ""
          
          # Test download
          puts "Testing file download..."
          downloaded_content = attachment.download
          
          if downloaded_content == test_content
            puts "✓ File downloaded successfully"
            puts "  Content matches uploaded content"
          else
            puts "✗ ERROR: Downloaded content does not match uploaded content"
            exit 1
          end
          puts ""
          
          # Test deletion
          puts "Testing file deletion..."
          attachment.purge
          puts "✓ File deleted successfully"
          puts ""
          
          # Clean up test user if it was created
          if test_user.email.start_with?("test-s3-")
            puts "Cleaning up test user..."
            test_user.destroy
            puts "✓ Test user removed"
            puts ""
          end
          
          puts "=" * 80
          puts "✓ ALL TESTS PASSED"
          puts "=" * 80
          puts ""
          puts "S3 integration is working correctly!"
          
        else
          puts "✗ ERROR: File attachment failed"
          exit 1
        end
        
      rescue Aws::S3::Errors::ServiceError => e
        puts "✗ ERROR: S3 Service Error"
        puts "  #{e.class}: #{e.message}"
        puts ""
        puts "Check your AWS credentials and bucket configuration."
        exit 1
      rescue => e
        puts "✗ ERROR: #{e.class}"
        puts "  #{e.message}"
        puts ""
        puts e.backtrace.first(5).join("\n")
        exit 1
      end
      
    elsif service == :local
      puts "Active Storage is configured for local storage (development mode)."
      puts "S3 is only used in production environment."
      puts ""
      puts "To test S3, set ACTIVE_STORAGE_SERVICE=amazon in your environment"
      puts "and ensure all AWS environment variables are set."
      
    else
      puts "Unknown Active Storage service: #{service}"
      exit 1
    end
  end
  
  desc "Show S3 configuration status"
  task status: :environment do
    puts "Active Storage Configuration Status"
    puts "=" * 80
    puts ""
    puts "Service: #{Rails.application.config.active_storage.service}"
    puts ""
    
    if Rails.application.config.active_storage.service == :amazon
      %w[AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION AWS_S3_BUCKET].each do |var|
        value = ENV[var]
        if value.present?
          display_value = var == 'AWS_SECRET_ACCESS_KEY' ? "[REDACTED]" : value
          puts "✓ #{var}: #{display_value}"
        else
          puts "✗ #{var}: not set"
        end
      end
    else
      puts "S3 is not configured (using #{Rails.application.config.active_storage.service} service)"
    end
  end
end

