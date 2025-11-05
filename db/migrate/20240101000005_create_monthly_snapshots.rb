class CreateMonthlySnapshots < ActiveRecord::Migration[7.1]
  def change
    create_table :monthly_snapshots do |t|
      t.references :snapshotable, polymorphic: true, null: false
      t.decimal :balance, precision: 10, scale: 2, null: false
      t.date :recorded_at, null: false

      t.timestamps
    end
    
    add_index :monthly_snapshots, [:snapshotable_type, :snapshotable_id]
    add_index :monthly_snapshots, :recorded_at
  end
end

