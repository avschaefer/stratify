class UserDataService
  def self.export_user_data(user)
    data = {
      user: {
        email: user.email,
        created_at: user.created_at,
        updated_at: user.updated_at
      },
      portfolios: user.portfolios.map(&:attributes),
      savings_accounts: user.savings_accounts.map(&:attributes),
      expenses: user.expenses.map(&:attributes),
      loans: user.loans.map(&:attributes),
      retirement_scenarios: user.retirement_scenarios.map(&:attributes),
      insurance_policies: user.insurance_policies.map(&:attributes),
      tax_scenarios: user.tax_scenarios.map(&:attributes),
      monthly_snapshots: user.savings_accounts.map(&:monthly_snapshots).flatten.map(&:attributes) +
                          user.expenses.map(&:monthly_snapshots).flatten.map(&:attributes),
      exported_at: Time.current.iso8601
    }
    
    json_data = JSON.pretty_generate(data)
    
    # Create a temporary file
    temp_file = Tempfile.new(['user_data', '.json'])
    temp_file.write(json_data)
    temp_file.rewind
    
    # Attach to user's data_files
    filename = "user_data_#{user.id}_#{Time.current.strftime('%Y%m%d_%H%M%S')}.json"
    user.data_files.attach(
      io: temp_file,
      filename: filename,
      content_type: 'application/json'
    )
    
    temp_file.close
    temp_file.unlink
    
    user.data_files.last
  end

  def self.import_user_data(user, attachment)
    return false unless attachment.present?
    
    json_data = attachment.download
    data = JSON.parse(json_data)
    
    # Import each type of data
    ActiveRecord::Base.transaction do
      # Portfolios
      if data['portfolios']
        data['portfolios'].each do |portfolio_data|
          portfolio_data.delete('id')
          portfolio_data.delete('created_at')
          portfolio_data.delete('updated_at')
          user.portfolios.create!(portfolio_data)
        end
      end
      
      # Savings Accounts
      if data['savings_accounts']
        data['savings_accounts'].each do |account_data|
          account_data.delete('id')
          account_data.delete('created_at')
          account_data.delete('updated_at')
          user.savings_accounts.create!(account_data)
        end
      end
      
      # Expenses
      if data['expenses']
        data['expenses'].each do |expense_data|
          expense_data.delete('id')
          expense_data.delete('created_at')
          expense_data.delete('updated_at')
          user.expenses.create!(expense_data)
        end
      end
      
      # Loans
      if data['loans']
        data['loans'].each do |loan_data|
          loan_data.delete('id')
          loan_data.delete('created_at')
          loan_data.delete('updated_at')
          user.loans.create!(loan_data)
        end
      end
      
      # Retirement Scenarios
      if data['retirement_scenarios']
        data['retirement_scenarios'].each do |scenario_data|
          scenario_data.delete('id')
          scenario_data.delete('created_at')
          scenario_data.delete('updated_at')
          user.retirement_scenarios.create!(scenario_data)
        end
      end
      
      # Insurance Policies
      if data['insurance_policies']
        data['insurance_policies'].each do |policy_data|
          policy_data.delete('id')
          policy_data.delete('created_at')
          policy_data.delete('updated_at')
          user.insurance_policies.create!(policy_data)
        end
      end
      
      # Tax Scenarios
      if data['tax_scenarios']
        data['tax_scenarios'].each do |scenario_data|
          scenario_data.delete('id')
          scenario_data.delete('created_at')
          scenario_data.delete('updated_at')
          user.tax_scenarios.create!(scenario_data)
        end
      end
      
      true
    end
  rescue => e
    Rails.logger.error "Error importing user data: #{e.message}"
    false
  end
end

