# Model Structure from data-models.xlsx

## User
- id: uuid (PK)
- created_at: datetime
- updated_at: datetime
- email: citext
- password: string
- referral_code: string (shareable unique code)
- subscription_period: rails enum (monthly default, yearly)
- subscription_price_cents: int
- stripe_customer_id: string
- stripe_subscription_id: string

Relationships:
- has_many :accounts, :transactions, :loans, :taxes, :retirements
- has_one :portfolio, :setting, :referral

## Portfolio
- id: uuid (PK)
- created_at: datetime
- updated_at: datetime
- user_id: uuid (FK to user.id)

Relationships:
- belongs_to :user
- has_many :holdings

## Holding
- id: uuid (PK)
- created_at: datetime
- updated_at: datetime
- portfolio_id: uuid (FK to portfolio.id)
- ticker: string
- name: string
- shares: decimal
- cost_basis_cents: bigint
- index_weight: decimal

Relationships:
- belongs_to :portfolio
- has_many :prices, :trades

## Price
- id: uuid (PK)
- created_at: datetime
- updated_at: datetime
- date: date
- holding_id: uuid (FK to holding.id)
- amount_cents: int

Relationships:
- belongs_to :holding

## Trade
- id: uuid (PK)
- created_at: datetime
- updated_at: datetime
- trade_date: date
- holding_id: uuid (FK to holding.id, only for investment trades)
- shares_quantity: bigint
- amount_cents: bigint
- price_cents: bigint
- trade_type: int (buy/sell)

Relationships:
- belongs_to :holding

## Account (replaces SavingsAccount)
- id: uuid (PK)
- created_at: datetime
- updated_at: datetime
- user_id: uuid (FK to user.id)
- account_type: rails enum (checking, savings, credit card)
- name: string
- index: int

Relationships:
- belongs_to :user
- has_many :balances

## Balance (replaces MonthlySnapshot)
- id: uuid (PK)
- created_at: datetime
- updated_at: datetime
- balance_date: date
- account_id: uuid (FK to account.id)
- amount_cents: int

Relationships:
- belongs_to :account

## Loan
- id: uuid (PK)
- created_at: datetime
- updated_at: datetime
- user_id: uuid (FK to user.id)
- name: string
- start_date: date
- end_date: date
- principal_cents: bigint
- rate_apy: decimal
- rate_apr: decimal
- payment_period: enum
- compounding_period: enum
- periodic_payment_cents: bigint
- term_years: decimal
- current_period: bigint
- current_balance_cents: bigint

Relationships:
- belongs_to :user

## Tax (replaces TaxScenario)
- id: uuid (PK)
- created_at: datetime
- updated_at: datetime
- user_id: uuid (FK to user.id)
- name: string
- year: int
- gross_income_cents: int
- deductions_cents: bigint
- taxable_income_cents: bigint (computed or stored)
- tax_paid_cents: bigint
- refund_cents: bigint
- payment_period: enum

Relationships:
- belongs_to :user

## Retirement (replaces RetirementScenario)
- id: uuid (PK)
- created_at: datetime
- updated_at: datetime
- user_id: uuid (FK to user.id)
- name: string
- age_start: int
- age_retirement: int
- age_end: bigint
- rate_inflation: decimal
- rate_contribution_growth: decimal
- rate_low: decimal (bonds/risk free)
- rate_mid: decimal (mid growth/risk)
- rate_high: decimal (high growth/risk)
- allocation_low_pre: decimal
- allocation_mid_pre: decimal
- allocation_high_pre: decimal
- allocation_low_post: decimal
- allocation_mid_post: decimal
- allocation_high_post: decimal
- contribution_annual_cents: bigint (savings per year)
- withdrawal_annual_pv_cents: bigint (target amount able to withdrawal per year in present value)
- withdrawal_rate_fv: decimal (percent of retirement fund drawn each year in future values)

Relationships:
- belongs_to :user

## Setting
- id: uuid (PK)
- created_at: datetime
- updated_at: datetime
- user_id: uuid (FK to user.id)
- name: string (profile name)
- date_type: string

Relationships:
- belongs_to :user

## Feedback
- id: uuid (PK)
- created_at: datetime
- updated_at: datetime
- user_id: uuid (FK to user.id)
- rating_net_promoter: int (0-10 NPS score)
- message: text (user feedback text)

Relationships:
- belongs_to :user

## Referral
- id: uuid (PK)
- created_at: datetime
- updated_at: datetime
- user_id: uuid (FK to user.id)
- referred_user_id: uuid (FK to user.id, belongs to referred_user)
- signup_date: date
- referral_code: string (human-readable code, unique)

Relationships:
- belongs_to :user
- belongs_to :referred_user, class_name: 'User'

