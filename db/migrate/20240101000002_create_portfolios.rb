class CreatePortfolios < ActiveRecord::Migration[7.1]
  def change
    create_table :portfolios do |t|
      t.references :user, null: false, foreign_key: true
      t.string :asset_type, null: false
      t.string :ticker, null: false
      t.date :purchase_date, null: false
      t.decimal :purchase_price, precision: 10, scale: 2, null: false
      t.decimal :quantity, precision: 10, scale: 2, null: false
      t.integer :status, default: 0

      t.timestamps
    end
  end
end

