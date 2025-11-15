class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :referral_code, uniqueness: true, allow_nil: true

  # Relationships from data model
  has_many :sessions, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :loans, dependent: :destroy
  has_many :taxes, dependent: :destroy
  has_many :retirements, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :insurance_policies, dependent: :destroy
  has_one :portfolio, dependent: :destroy
  has_one :setting, dependent: :destroy
  has_one :referral, dependent: :destroy
  has_many :feedbacks, dependent: :destroy
  
  has_many_attached :data_files
  
  enum :subscription_period, { monthly: 'monthly', yearly: 'yearly' }, default: 'monthly'
  
  # Set defaults for settings
  after_initialize :set_defaults, unless: :persisted?
  before_create :generate_referral_code, unless: :referral_code?
  
  private
  
  def set_defaults
    self.currency ||= 'USD'
    self.timezone ||= 'America/New_York'
    self.date_format ||= 'MM/DD/YYYY'
    self.subscription_period ||= 'monthly'
  end
  
  def generate_referral_code
    loop do
      self.referral_code = SecureRandom.alphanumeric(8).upcase
      break unless User.exists?(referral_code: self.referral_code)
    end
  end
end
