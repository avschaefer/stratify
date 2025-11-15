class Feedback < ApplicationRecord
  belongs_to :user
  
  validates :rating_net_promoter, presence: true, 
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }
  validates :message, presence: true
end

