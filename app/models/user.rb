class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  has_many :sessions, dependent: :destroy
  has_many :portfolios, dependent: :destroy
  has_many :savings_accounts, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :loans, dependent: :destroy
  has_many :retirement_scenarios, dependent: :destroy
  has_many :insurance_policies, dependent: :destroy
  has_many :tax_scenarios, dependent: :destroy
  
  has_many_attached :data_files
  
  # Set defaults for settings
  after_initialize :set_defaults, unless: :persisted?
  
  private
  
  def set_defaults
    self.currency ||= 'USD'
    self.timezone ||= 'America/New_York'
    self.date_format ||= 'MM/DD/YYYY'
  end
end
