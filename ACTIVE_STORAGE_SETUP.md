# Active Storage Configuration Guide

## Overview

This application uses Active Storage for file attachments (currently user data exports). The configuration supports both local disk storage (development) and Amazon S3 (production).

## Development Environment (Local Storage)

Active Storage is configured to use local disk storage in development by default. Files are stored in the `storage/` directory at the project root.

### Configuration

The development environment (`config/environments/development.rb`) is configured to use:
- Service: `:local` (defined in `config/storage.yml`)
- Storage root: `storage/` directory

### Usage

Files attached via Active Storage will automatically be stored locally. No additional setup is required for development.

## Production Environment (S3 Storage)

For production deployments, Active Storage is configured to use Amazon S3.

### Required Environment Variables

Set the following environment variables in your production environment:

```
AWS_ACCESS_KEY_ID=your_access_key_id
AWS_SECRET_ACCESS_KEY=your_secret_access_key
AWS_REGION=us-east-1
AWS_S3_BUCKET=your_bucket_name
```

### S3 Bucket Setup

1. **Create an S3 Bucket**
   - Log into AWS Console
   - Navigate to S3 service
   - Create a new bucket with a unique name
   - Choose your preferred region

2. **Configure Bucket Permissions**
   - Ensure your AWS credentials have permissions to:
     - `s3:PutObject`
     - `s3:GetObject`
     - `s3:DeleteObject`
     - `s3:ListBucket`

3. **Set Environment Variables**
   - Add the environment variables listed above to your production environment
   - For Heroku: `heroku config:set AWS_ACCESS_KEY_ID=...`
   - For other platforms: Set via your platform's environment variable configuration

### Configuration Files

- `config/storage.yml`: Defines storage services (local, test, amazon)
- `config/environments/production.rb`: Sets Active Storage service to `:amazon`
- `config/environments/development.rb`: Sets Active Storage service to `:local`

### Testing Active Storage

To test Active Storage in development:

1. Export data from Settings page (creates attachment)
2. Check `storage/` directory for uploaded files
3. Verify files can be downloaded

### Gems Required

The following gems are already in the Gemfile:
- `aws-sdk-s3` (for S3 integration)
- Active Storage is built into Rails 8.0

### File Size Limits

Currently no file size limits are enforced. Consider adding validation if needed:

```ruby
# In User model or service
validates :data_files, blob: { size_range: 1..(10.megabytes) }
```

### Troubleshooting

**Issue: Files not uploading in development**
- Check that `storage/` directory exists and is writable
- Ensure Active Storage migrations have been run: `rails db:migrate`

**Issue: S3 uploads failing in production**
- Verify all AWS environment variables are set correctly
- Check AWS credentials have proper permissions
- Verify bucket name matches exactly
- Check region matches bucket region

**Issue: Files not downloading**
- Check that `rails_blob_path` helper is used correctly
- Verify Active Storage routes are configured (should be automatic in Rails 8)

### Migration Status

Active Storage tables have been created via migration:
- `active_storage_blobs`
- `active_storage_attachments`
- `active_storage_variant_records`

These tables are already in the database schema.

