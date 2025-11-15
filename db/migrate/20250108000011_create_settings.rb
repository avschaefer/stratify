class CreateSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :settings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name  # profile name
      t.string :date_type

      t.timestamps
    end
  end
end

