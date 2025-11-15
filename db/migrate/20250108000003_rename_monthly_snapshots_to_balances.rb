class RenameMonthlySnapshotsToBalances < ActiveRecord::Migration[8.0]
  def up
    rename_table :monthly_snapshots, :balances
    
    # Rename snapshotable_id to account_id (if it still exists as snapshotable_id)
    if column_exists?(:balances, :snapshotable_id)
      rename_column :balances, :snapshotable_id, :account_id
    end
    # account_id should now exist (either from rename above or already renamed)
    
    # Remove polymorphic type column (could be balanceable_type from migration 2, or snapshotable_type)
    if column_exists?(:balances, :balanceable_type)
      remove_column :balances, :balanceable_type
    elsif column_exists?(:balances, :snapshotable_type)
      remove_column :balances, :snapshotable_type
    end
    
    # Rename other columns
    rename_column :balances, :recorded_at, :balance_date if column_exists?(:balances, :recorded_at)
    rename_column :balances, :balance, :amount_cents if column_exists?(:balances, :balance)
    
    # Change balance to integer cents
    change_column :balances, :amount_cents, :bigint if column_exists?(:balances, :amount_cents)
    
    # Remove old polymorphic indexes
    if index_exists?(:balances, [:balanceable_type, :account_id])
      remove_index :balances, [:balanceable_type, :account_id]
    end
    if index_exists?(:balances, [:snapshotable_type, :snapshotable_id])
      remove_index :balances, [:snapshotable_type, :snapshotable_id]
    end
    
    # account_id already exists from rename above, just ensure foreign key and index
    unless foreign_key_exists?(:balances, :accounts)
      add_foreign_key :balances, :accounts, column: :account_id
    end
    
    unless index_exists?(:balances, :account_id)
      add_index :balances, :account_id
    end
    
    # Ensure account_id is not null
    change_column_null :balances, :account_id, false
  end
  
  def down
    rename_table :balances, :monthly_snapshots
    rename_column :monthly_snapshots, :account_id, :snapshotable_id if column_exists?(:monthly_snapshots, :account_id)
    rename_column :monthly_snapshots, :balance_date, :recorded_at if column_exists?(:monthly_snapshots, :balance_date)
    rename_column :monthly_snapshots, :amount_cents, :balance if column_exists?(:monthly_snapshots, :amount_cents)
    
    change_column :monthly_snapshots, :balance, :decimal, precision: 10, scale: 2 if column_exists?(:monthly_snapshots, :balance)
    
    remove_reference :monthly_snapshots, :account if foreign_key_exists?(:monthly_snapshots, :accounts)
    add_column :monthly_snapshots, :snapshotable_type, :string
    add_column :monthly_snapshots, :snapshotable_id, :integer
    add_index :monthly_snapshots, [:snapshotable_type, :snapshotable_id]
  end
end

