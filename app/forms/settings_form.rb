# frozen_string_literal: true

# Form object for handling user settings updates
class SettingsForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  
  attribute :email, :string
  attribute :currency, :string, default: 'USD'
  attribute :timezone, :string, default: 'America/New_York'
  attribute :date_format, :string, default: 'MM/DD/YYYY'
  
  attr_reader :user
  
  VALID_CURRENCIES = %w[USD EUR GBP CAD AUD JPY CHF].freeze
  VALID_TIMEZONES = %w[
    America/New_York America/Chicago America/Denver America/Los_Angeles
    America/Phoenix America/Anchorage Pacific/Honolulu Europe/London
    Europe/Paris Asia/Tokyo Asia/Hong_Kong Australia/Sydney
  ].freeze
  VALID_DATE_FORMATS = %w[MM/DD/YYYY DD/MM/YYYY YYYY-MM-DD DD.MM.YYYY].freeze
  
  def initialize(user:, attributes: {})
    @user = user
    super(attributes)
    
    assign_attributes_from_user
  end
  
  def save
    return false unless valid?
    
    user.update(form_attributes)
    user.valid?
  end
  
  def update(attributes)
    assign_attributes(attributes)
    save
  end
  
  def valid?
    super
    validate_email
    validate_currency
    validate_timezone
    validate_date_format
    errors.empty?
  end
  
  private
  
  def assign_attributes_from_user
    self.email = user.email
    self.currency = user.currency || 'USD'
    self.timezone = user.timezone || 'America/New_York'
    self.date_format = user.date_format || 'MM/DD/YYYY'
  end
  
  def form_attributes
    {
      email: email,
      currency: currency,
      timezone: timezone,
      date_format: date_format
    }
  end
  
  def validate_email
    errors.add(:email, "can't be blank") if email.blank?
    errors.add(:email, "is invalid") if email.present? && !email.match?(URI::MailTo::EMAIL_REGEXP)
    errors.add(:email, "is already taken") if email.present? && user.email != email && User.exists?(email: email.downcase)
  end
  
  def validate_currency
    errors.add(:currency, "is invalid") if currency.present? && !VALID_CURRENCIES.include?(currency)
  end
  
  def validate_timezone
    errors.add(:timezone, "is invalid") if timezone.present? && !VALID_TIMEZONES.include?(timezone)
  end
  
  def validate_date_format
    errors.add(:date_format, "is invalid") if date_format.present? && !VALID_DATE_FORMATS.include?(date_format)
  end
end

