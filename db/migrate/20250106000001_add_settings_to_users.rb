class AddSettingsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :currency, :string, default: 'USD'
    add_column :users, :timezone, :string, default: 'America/New_York'
    add_column :users, :date_format, :string, default: 'MM/DD/YYYY'
  end
end

