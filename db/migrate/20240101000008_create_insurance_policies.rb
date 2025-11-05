class CreateInsurancePolicies < ActiveRecord::Migration[7.1]
  def change
    create_table :insurance_policies do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :policy_type, null: false
      t.string :provider, null: false
      t.decimal :coverage_amount, precision: 12, scale: 2, null: false
      t.decimal :premium, precision: 10, scale: 2, null: false
      t.decimal :term_years, precision: 5, scale: 2, null: false
      t.integer :status, default: 0
      t.text :notes

      t.timestamps
    end
  end
end

