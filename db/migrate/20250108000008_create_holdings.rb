class CreateHoldings < ActiveRecord::Migration[8.0]
  def change
    create_table :holdings do |t|
      t.references :portfolio, null: false, foreign_key: true
      t.string :ticker, null: false
      t.string :name
      t.decimal :shares, precision: 10, scale: 2
      t.bigint :cost_basis_cents
      t.decimal :index_weight, precision: 5, scale: 2

      t.timestamps
    end
    
    add_index :holdings, :ticker
  end
end

