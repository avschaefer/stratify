class CreateSavingsAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :savings_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :account_type, null: false
      t.text :notes

      t.timestamps
    end
  end
end

