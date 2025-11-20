class AddTradeTypeToHoldings < ActiveRecord::Migration[8.0]
  def change
    add_column :holdings, :trade_type, :string
    
    # Set default to 'buy' for existing trades
    execute <<-SQL
      UPDATE holdings SET trade_type = 'buy' WHERE entry_type = 'trade' AND trade_type IS NULL;
    SQL
  end
end

