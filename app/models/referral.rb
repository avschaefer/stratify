class Referral < ApplicationRecord
  belongs_to :user
  belongs_to :referred_user, class_name: 'User'
  
  validates :referral_code, presence: true, uniqueness: true
  validates :signup_date, presence: true
end

