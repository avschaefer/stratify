class CreateLoans < ActiveRecord::Migration[7.1]
  def change
    create_table :loans do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :principal, precision: 10, scale: 2, null: false
      t.decimal :interest_rate, precision: 5, scale: 2, null: false
      t.decimal :term_years, precision: 5, scale: 2, null: false
      t.integer :status, default: 0

      t.timestamps
    end
  end
end

