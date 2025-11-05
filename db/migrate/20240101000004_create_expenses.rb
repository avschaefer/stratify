class CreateExpenses < ActiveRecord::Migration[7.1]
  def change
    create_table :expenses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :notes

      t.timestamps
    end
  end
end

