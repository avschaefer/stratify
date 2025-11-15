# frozen_string_literal: true

# Service for analyzing insurance policies and calculating metrics
class InsuranceAnalysisService
  attr_reader :policy, :user
  
  def initialize(policy:, user:)
    @policy = policy
    @user = user
  end
  
  # Analyze policy and return comprehensive metrics
  def analyze
    {
      monthly_premium: monthly_premium.round(2),
      annual_premium: annual_premium.round(2),
      total_cost: total_cost.round(2),
      coverage_amount: coverage_amount.round(2),
      cost_per_thousand: cost_per_thousand.round(2),
      coverage_adequacy: coverage_adequacy.round(2),
      suggested_coverage: suggested_coverage.round(2),
      months_remaining: months_remaining
    }
  end
  
  # Calculate monthly premium
  def monthly_premium
    policy.premium || 0
  end
  
  # Calculate annual premium
  def annual_premium
    monthly_premium * 12
  end
  
  # Calculate total cost over term
  def total_cost
    annual_premium * (policy.term_years || 1)
  end
  
  # Get coverage amount
  def coverage_amount
    policy.coverage_amount || 0
  end
  
  # Calculate cost per thousand dollars of coverage
  def cost_per_thousand
    return 0 if coverage_amount <= 0
    (annual_premium / coverage_amount * 1000).round(2)
  end
  
  # Calculate coverage adequacy percentage
  def coverage_adequacy
    return 0 if coverage_amount <= 0
    suggested = suggested_coverage
    return 0 if suggested <= 0
    (coverage_amount / suggested * 100).round(2)
  end
  
  # Suggest appropriate coverage amount based on policy type and user assets
  def suggested_coverage
    case policy.policy_type
    when 'life'
      # Life insurance: 2x total assets (including portfolios and savings)
      total_assets * 2
    when 'health'
      # Health insurance: typically based on deductible, use coverage amount as baseline
      coverage_amount
    when 'auto'
      # Auto insurance: typically based on vehicle value, use coverage amount
      coverage_amount
    when 'home'
      # Home insurance: typically 80-100% of home value, use coverage amount
      coverage_amount
    else
      coverage_amount
    end
  end
  
  # Calculate months remaining in term
  def months_remaining
    term_years = policy.term_years || 1
    term_years > 0 ? (term_years * 12) : 0
  end
  
  private
  
  # Calculate user's total assets (portfolios + savings)
  def total_assets
    portfolio_value = user.portfolio&.total_value || 0
    
    savings_value = user.accounts.sum do |account|
      (account.balances
        .find_by(balance_date: Date.today.beginning_of_month)&.amount_cents || 0) / 100.0
    end
    
    portfolio_value + savings_value
  end
end

