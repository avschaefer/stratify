class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :portfolios, dependent: :destroy
  has_many :savings_accounts, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :loans, dependent: :destroy
  has_many :retirement_scenarios, dependent: :destroy
  has_many :insurance_policies, dependent: :destroy
  has_many :tax_scenarios, dependent: :destroy
end

