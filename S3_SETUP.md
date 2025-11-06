# S3 Setup Guide

## AWS S3 Bucket Creation

### Step 1: Create S3 Bucket

1. Log into AWS Console: https://console.aws.amazon.com/s3/
2. Click "Create bucket"
3. Configure bucket settings:
   - **Bucket name**: Choose a unique name (e.g., `financial-planner-user-data-{your-identifier}`)
   - **Region**: Select your preferred region (default: `us-east-1`)
   - **Object Ownership**: Choose "ACLs disabled" (recommended) or "ACLs enabled"
   - **Block Public Access**: Keep enabled for security (this is for private file storage)
   - **Bucket Versioning**: Enable if you want to track file versions (recommended)
   - **Default encryption**: Enable server-side encryption with AWS-managed keys (recommended)
4. Click "Create bucket"

### Step 2: Configure Bucket Permissions

After creating the bucket:

1. Go to bucket → Permissions tab
2. **Bucket Policy** (if needed): The IAM user credentials will handle access, so bucket policy may not be needed
3. **CORS Configuration** (if serving files directly): Not needed for Active Storage attachments served through Rails

### Step 3: Configure Lifecycle Policies (Optional)

To manage storage costs:

1. Go to bucket → Management tab
2. Add lifecycle rule:
   - **Name**: `cleanup-old-files`
   - **Rule scope**: Apply to all objects
   - **Actions**: 
     - Transition to Glacier storage after 90 days (optional)
     - Delete objects after 1 year (optional)

## AWS IAM User/Policy Creation

### Step 1: Create IAM User

1. Log into AWS Console: https://console.aws.amazon.com/iam/
2. Navigate to "Users" → "Create user"
3. **User name**: `financial-planner-s3-user` (or your preferred name)
4. **Select AWS credential type**: Check "Access key - Programmatic access"
5. Click "Next"

### Step 2: Attach Permissions Policy

1. **Permission options**: Choose "Attach policies directly"
2. Click "Create policy"
3. Use the JSON editor and paste:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR-BUCKET-NAME/*",
        "arn:aws:s3:::YOUR-BUCKET-NAME"
      ]
    }
  ]
}
```

Replace `YOUR-BUCKET-NAME` with your actual bucket name.

4. Name the policy: `FinancialPlannerS3Access`
5. Click "Create policy"
6. Go back to user creation and attach this policy

### Step 3: Generate Access Keys

1. After creating the user, you'll see the access key and secret access key
2. **IMPORTANT**: Copy these immediately - you won't be able to see the secret key again
3. Store them securely (you'll add them to environment variables)

### Step 4: Set Up Programmatic Access

The access keys are already generated. Note:
- **Access Key ID**: Use for `AWS_ACCESS_KEY_ID`
- **Secret Access Key**: Use for `AWS_SECRET_ACCESS_KEY`

## Environment Variable Configuration

### Required Variables

Set these environment variables in your production environment:

```bash
AWS_ACCESS_KEY_ID=your_access_key_id_here
AWS_SECRET_ACCESS_KEY=your_secret_access_key_here
AWS_REGION=us-east-1  # or your bucket's region
AWS_S3_BUCKET=your-bucket-name-here
```

### Platform-Specific Setup

#### Heroku

```bash
heroku config:set AWS_ACCESS_KEY_ID=your_access_key_id
heroku config:set AWS_SECRET_ACCESS_KEY=your_secret_access_key
heroku config:set AWS_REGION=us-east-1
heroku config:set AWS_S3_BUCKET=your-bucket-name
```

#### Docker/Container

Add to your `docker-compose.yml` or container environment:

```yaml
environment:
  AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}
  AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY}
  AWS_REGION: ${AWS_REGION:-us-east-1}
  AWS_S3_BUCKET: ${AWS_S3_BUCKET}
```

#### Linux/Unix Server

Add to `/etc/environment` or your deployment script:

```bash
export AWS_ACCESS_KEY_ID=your_access_key_id
export AWS_SECRET_ACCESS_KEY=your_secret_access_key
export AWS_REGION=us-east-1
export AWS_S3_BUCKET=your-bucket-name
```

#### Windows Server

Set via System Properties → Environment Variables or PowerShell:

```powershell
[Environment]::SetEnvironmentVariable("AWS_ACCESS_KEY_ID", "your_access_key_id", "Machine")
[Environment]::SetEnvironmentVariable("AWS_SECRET_ACCESS_KEY", "your_secret_access_key", "Machine")
[Environment]::SetEnvironmentVariable("AWS_REGION", "us-east-1", "Machine")
[Environment]::SetEnvironmentVariable("AWS_S3_BUCKET", "your-bucket-name", "Machine")
```

## Verification

### Test S3 Connection

Run the Rails console in production mode (or with credentials set):

```ruby
# In rails console
Rails.application.config.active_storage.service
# Should return :amazon

# Test upload
user = User.first
test_file = Tempfile.new(['test', '.txt'])
test_file.write("Test content")
test_file.rewind
user.data_files.attach(io: test_file, filename: 'test.txt', content_type: 'text/plain')
test_file.close

# Check if attachment was created
user.data_files.last
# Should return the attachment object

# Test download
user.data_files.last.download
# Should return the file content
```

## Troubleshooting

### Issue: "Access Denied" errors

- Verify IAM user has correct permissions
- Check bucket name matches exactly (case-sensitive)
- Verify region matches bucket region
- Check that bucket policy doesn't block the IAM user

### Issue: "Bucket not found"

- Verify bucket name is correct
- Check region matches
- Ensure bucket exists in your AWS account

### Issue: Credentials not found

- Verify environment variables are set
- Check that variables are loaded in production environment
- Restart Rails server after setting environment variables

### Issue: Files upload but can't download

- Check Active Storage routes are configured (should be automatic)
- Verify CORS settings if accessing via JavaScript
- Check file permissions in S3 bucket

## Security Best Practices

1. **Never commit credentials** to version control
2. **Use IAM roles** instead of access keys when possible (e.g., on EC2)
3. **Rotate access keys** regularly (every 90 days recommended)
4. **Limit S3 permissions** to only what's needed
5. **Enable bucket versioning** for file recovery
6. **Use bucket encryption** for sensitive data
7. **Monitor S3 access** via CloudTrail

## Cost Considerations

- **Storage**: ~$0.023 per GB/month (varies by region)
- **Requests**: 
  - PUT requests: $0.005 per 1,000 requests
  - GET requests: $0.0004 per 1,000 requests
- **Data transfer**: First 100 GB/month free, then varies

For typical usage (< 1000 files, < 10 GB), expect < $1/month.

