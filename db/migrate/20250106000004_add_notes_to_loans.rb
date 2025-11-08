class AddNotesToLoans < ActiveRecord::Migration[8.0]
  def change
    add_column :loans, :notes, :text
  end
end

