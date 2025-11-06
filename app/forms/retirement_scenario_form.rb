# frozen_string_literal: true

# Form object for handling retirement scenario creation and updates
class RetirementScenarioForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  
  attribute :name, :string
  attribute :target_date, :date
  attribute :current_savings, :decimal
  attribute :monthly_contribution, :decimal
  attribute :target_amount, :decimal
  attribute :expected_return_rate, :decimal
  attribute :risk_level, :string
  
  attr_reader :scenario, :user
  
  def initialize(user:, scenario: nil, attributes: {})
    @user = user
    @scenario = scenario
    super(attributes)
    
    if scenario
      assign_attributes_from_scenario
    end
  end
  
  def save
    return false unless valid?
    
    if scenario
      scenario.update(form_attributes)
    else
      @scenario = user.retirement_scenarios.create(form_attributes)
    end
    
    scenario.persisted? && scenario.valid?
  end
  
  def update(attributes)
    assign_attributes(attributes)
    save
  end
  
  def valid?
    super
    validate_required_fields
    validate_numerical_fields
    validate_dates
    errors.empty?
  end
  
  private
  
  def assign_attributes_from_scenario
    self.name = scenario.name
    self.target_date = scenario.target_date
    self.current_savings = scenario.current_savings
    self.monthly_contribution = scenario.monthly_contribution
    self.target_amount = scenario.target_amount
    self.expected_return_rate = scenario.expected_return_rate
    self.risk_level = scenario.risk_level
  end
  
  def form_attributes
    {
      name: name,
      target_date: target_date,
      current_savings: current_savings,
      monthly_contribution: monthly_contribution,
      target_amount: target_amount,
      expected_return_rate: expected_return_rate,
      risk_level: risk_level
    }
  end
  
  def validate_required_fields
    errors.add(:name, "can't be blank") if name.blank?
    errors.add(:target_date, "can't be blank") if target_date.nil?
    errors.add(:current_savings, "can't be blank") if current_savings.nil?
    errors.add(:monthly_contribution, "can't be blank") if monthly_contribution.nil?
    errors.add(:target_amount, "can't be blank") if target_amount.nil?
    errors.add(:expected_return_rate, "can't be blank") if expected_return_rate.nil?
  end
  
  def validate_numerical_fields
    errors.add(:current_savings, "must be non-negative") if current_savings.present? && current_savings < 0
    errors.add(:monthly_contribution, "must be non-negative") if monthly_contribution.present? && monthly_contribution < 0
    errors.add(:target_amount, "must be greater than 0") if target_amount.present? && target_amount <= 0
    errors.add(:expected_return_rate, "must be non-negative") if expected_return_rate.present? && expected_return_rate < 0
  end
  
  def validate_dates
    if target_date.present? && target_date < Date.today
      errors.add(:target_date, "must be in the future")
    end
  end
end

