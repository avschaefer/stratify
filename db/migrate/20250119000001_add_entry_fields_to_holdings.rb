class AddEntryFieldsToHoldings < ActiveRecord::Migration[8.0]
  def change
    add_column :holdings, :entry_type, :string, default: 'holding'
    add_column :holdings, :entry_date, :date
    
    # Set entry_date to created_at date for existing records
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE holdings SET entry_date = DATE(created_at) WHERE entry_date IS NULL;
        SQL
      end
    end
    
    add_index :holdings, :entry_type
    add_index :holdings, :entry_date
  end
end

