class CreateTrades < ActiveRecord::Migration[8.0]
  def change
    create_table :trades do |t|
      t.references :holding, null: true, foreign_key: true  # nullable for cash trades
      t.date :trade_date, null: false
      t.bigint :shares_quantity
      t.bigint :amount_cents
      t.bigint :price_cents
      t.integer :trade_type  # buy/sell enum

      t.timestamps
    end
    
    add_index :trades, [:holding_id, :trade_date]
  end
end

