class RenameSavingsAccountsToAccounts < ActiveRecord::Migration[8.0]
  def up
    rename_table :savings_accounts, :accounts
    rename_column :monthly_snapshots, :snapshotable_type, :balanceable_type if column_exists?(:monthly_snapshots, :snapshotable_type)
    # Update polymorphic association - will be handled in model
  end
  
  def down
    rename_table :accounts, :savings_accounts
    rename_column :monthly_snapshots, :balanceable_type, :snapshotable_type if column_exists?(:monthly_snapshots, :balanceable_type)
  end
end

