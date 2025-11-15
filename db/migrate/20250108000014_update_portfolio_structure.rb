class UpdatePortfolioStructure < ActiveRecord::Migration[8.0]
  def change
    # Portfolio should only have user_id - remove other fields that belong to Holding
    remove_column :portfolios, :asset_type if column_exists?(:portfolios, :asset_type)
    remove_column :portfolios, :ticker if column_exists?(:portfolios, :ticker)
    remove_column :portfolios, :purchase_date if column_exists?(:portfolios, :purchase_date)
    remove_column :portfolios, :purchase_price if column_exists?(:portfolios, :purchase_price)
    remove_column :portfolios, :quantity if column_exists?(:portfolios, :quantity)
    remove_column :portfolios, :status if column_exists?(:portfolios, :status)
    
    # Ensure user_id is unique (has_one relationship)
    # Check if index already exists by checking connection indexes
    existing_indexes = connection.indexes(:portfolios)
    index_exists = existing_indexes.any? { |idx| idx.columns == ['user_id'] }
    
    unless index_exists
      add_index :portfolios, :user_id, unique: true
    end
  end
end

