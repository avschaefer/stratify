class AddPositionToSavingsAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :savings_accounts, :position, :integer
    
    # Set initial positions based on current order (account_type, name)
    reversible do |dir|
      dir.up do
        User.find_each do |user|
          user.savings_accounts.order(:account_type, :name).each_with_index do |account, index|
            account.update_column(:position, index)
          end
        end
      end
    end
  end
end

