class CreateTaxScenarios < ActiveRecord::Migration[7.1]
  def change
    create_table :tax_scenarios do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :year, null: false
      t.decimal :income, precision: 12, scale: 2, null: false, default: 0
      t.decimal :deductions, precision: 12, scale: 2, null: false, default: 0
      t.text :notes

      t.timestamps
    end
  end
end

