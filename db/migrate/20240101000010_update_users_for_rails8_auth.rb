class UpdateUsersForRails8Auth < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :encrypted_password, :string
    remove_column :users, :reset_password_token, :string
    remove_column :users, :reset_password_sent_at, :datetime
    remove_column :users, :remember_created_at, :datetime
    
    remove_index :users, :reset_password_token if index_exists?(:users, :reset_password_token)
    
    add_column :users, :password_digest, :string
  end
end

