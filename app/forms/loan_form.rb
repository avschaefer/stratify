# frozen_string_literal: true

# Form object for handling loan creation and updates
# Handles validation and rate type conversions before saving
class LoanForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  
  attribute :name, :string
  attribute :principal, :decimal
  attribute :interest_rate, :decimal
  attribute :term_years, :decimal
  attribute :rate_type, :string, default: 'apr'
  attribute :payment_frequency, :string, default: 'monthly'
  attribute :compounding_period, :string, default: 'monthly'
  attribute :status, :string, default: 'draft'
  attribute :notes, :string
  
  attr_reader :loan, :user
  
  def initialize(user:, loan: nil, attributes: {})
    @user = user
    @loan = loan
    super(attributes)
    
    if loan
      assign_attributes_from_loan
    end
  end
  
  def save
    return false unless valid?
    
    if loan
      loan.update(form_attributes)
    else
      @loan = user.loans.create(form_attributes)
    end
    
    loan.persisted?
  end
  
  def update(attributes)
    assign_attributes(attributes)
    save
  end
  
  def valid?
    super
    validate_required_fields
    validate_numerical_fields
    errors.empty?
  end
  
  private
  
  def assign_attributes_from_loan
    self.name = loan.name
    self.principal = loan.principal
    self.interest_rate = loan.interest_rate
    self.term_years = loan.term_years
    self.rate_type = loan.rate_type || 'apr'
    self.payment_frequency = loan.payment_frequency || 'monthly'
    self.compounding_period = loan.compounding_period || 'monthly'
    self.status = loan.status
    self.notes = loan.notes
  end
  
  def form_attributes
    {
      name: name,
      principal: principal,
      interest_rate: interest_rate,
      term_years: term_years,
      rate_type: rate_type,
      payment_frequency: payment_frequency,
      compounding_period: compounding_period,
      status: status,
      notes: notes
    }
  end
  
  def validate_required_fields
    errors.add(:name, "can't be blank") if name.blank?
    errors.add(:principal, "can't be blank") if principal.nil?
    errors.add(:interest_rate, "can't be blank") if interest_rate.nil?
    errors.add(:term_years, "can't be blank") if term_years.nil?
  end
  
  def validate_numerical_fields
    errors.add(:principal, "must be greater than 0") if principal.present? && principal <= 0
    errors.add(:interest_rate, "must be non-negative") if interest_rate.present? && interest_rate < 0
    errors.add(:term_years, "must be greater than 0") if term_years.present? && term_years <= 0
  end
end

