class Expense < ApplicationRecord
  belongs_to :user
  has_many :monthly_snapshots, as: :snapshotable, dependent: :destroy
  
  validates :name, presence: true
end

