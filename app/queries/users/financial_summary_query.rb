# frozen_string_literal: true

# Query object for aggregating user financial summary data efficiently
module Users
  class FinancialSummaryQuery
    def initialize(user)
      @user = user
    end
    
    def call
      {
        portfolios: portfolios_summary,
        savings_accounts: savings_summary,
        loans: loans_summary,
        expenses: expenses_summary,
        total_assets: total_assets,
        total_liabilities: total_liabilities,
        net_worth: net_worth
      }
    end
    
    private
    
    def portfolios_summary
      {
        count: @user.portfolios.count,
        total_value: @user.portfolios.sum { |p| (p.purchase_price || 0) * (p.quantity || 0) },
        active_count: @user.portfolios.where(status: 'active').count
      }
    end
    
    def savings_summary
      current_month = Date.today.beginning_of_month
      total_balance = @user.accounts.sum do |account|
        account.balances.find_by(balance_date: current_month)&.amount_cents || 0
      end
      
      {
        count: @user.accounts.count,
        total_balance: total_balance / 100.0  # Convert cents to dollars
      }
    end
    
    def loans_summary
      {
        count: @user.loans.count,
        total_principal: @user.loans.sum(:principal) || 0,
        active_count: @user.loans.where(status: 'active').count
      }
    end
    
    def expenses_summary
      {
        count: @user.expenses.count
      }
    end
    
    def total_assets
      portfolio_value = portfolios_summary[:total_value]
      savings_value = savings_summary[:total_balance]
      portfolio_value + savings_value
    end
    
    def total_liabilities
      loans_summary[:total_principal]
    end
    
    def net_worth
      total_assets - total_liabilities
    end
  end
end

