class CreatePrices < ActiveRecord::Migration[8.0]
  def change
    create_table :prices do |t|
      t.references :holding, null: false, foreign_key: true
      t.date :date, null: false
      t.integer :amount_cents

      t.timestamps
    end
    
    add_index :prices, [:holding_id, :date]
  end
end

