class CreateReferrals < ActiveRecord::Migration[8.0]
  def change
    create_table :referrals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :referred_user, null: false, foreign_key: { to_table: :users }
      t.date :signup_date
      t.string :referral_code  # human-readable code, unique

      t.timestamps
    end
    
    add_index :referrals, :referral_code, unique: true
  end
end

