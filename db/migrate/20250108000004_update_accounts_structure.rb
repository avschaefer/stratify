class UpdateAccountsStructure < ActiveRecord::Migration[8.0]
  def change
    # Rename position to index if it exists
    rename_column :accounts, :position, :index if column_exists?(:accounts, :position)
    
    # Ensure account_type is integer enum
    change_column :accounts, :account_type, :integer, null: false if column_exists?(:accounts, :account_type)
  end
end

