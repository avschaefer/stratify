class SettingsController < ApplicationController
  def index
    # Mock user settings data
    @user_settings = OpenStruct.new(
      first_name: 'John',
      last_name: 'Doe',
      email: 'demo@example.com',
      phone: '(555) 123-4567',
      date_of_birth: Date.new(1985, 5, 15),
      address: '123 Main St',
      city: 'New York',
      state: 'NY',
      zip_code: '10001',
      country: 'United States'
    )
    
    @account_settings = OpenStruct.new(
      username: 'johndoe',
      password: '••••••••',
      email_notifications: true,
      sms_notifications: false,
      currency: 'USD',
      timezone: 'America/New_York',
      date_format: 'MM/DD/YYYY'
    )
  end
  
  def update
    redirect_to settings_path, notice: 'Settings updated successfully.'
  end
end

