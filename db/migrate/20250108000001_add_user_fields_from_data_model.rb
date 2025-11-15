class AddUserFieldsFromDataModel < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :referral_code, :string
    add_column :users, :subscription_period, :string, default: 'monthly'
    add_column :users, :subscription_price_cents, :integer
    add_column :users, :stripe_customer_id, :string
    add_column :users, :stripe_subscription_id, :string
    
    add_index :users, :referral_code, unique: true
  end
end

