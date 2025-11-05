class MonthlySnapshot < ApplicationRecord
  belongs_to :snapshotable, polymorphic: true
  
  validates :balance, presence: true, numericality: true
  validates :recorded_at, presence: true
end

