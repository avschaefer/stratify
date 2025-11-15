# Migration Summary - Data Models Update

## Overview
This document summarizes all changes made to align the application with the data models defined in `data-models.xlsx`.

## Model Changes

### Renamed Models
1. **SavingsAccount → Account**
   - Table: `savings_accounts` → `accounts`
   - Controller: `SavingsAccountsController` → `AccountsController`
   - Routes: `savings_accounts_path` → `accounts_path`
   - Field changes: `position` → `index`

2. **MonthlySnapshot → Balance**
   - Table: `monthly_snapshots` → `balances`
   - Controller: `MonthlySnapshotsController` → `BalancesController`
   - Routes: `monthly_snapshots_path` → `balances_path`
   - Field changes:
     - `snapshotable_id` → `account_id` (direct FK, no longer polymorphic)
     - `snapshotable_type` → removed
     - `recorded_at` → `balance_date`
     - `balance` → `amount_cents` (decimal → bigint, stored in cents)

3. **TaxScenario → Tax**
   - Table: `tax_scenarios` → `taxes`
   - Controller: `TaxScenariosController` → `TaxesController`
   - Routes: `tax_scenarios_path` → `taxes_path`
   - Field changes: All monetary fields now use `_cents` suffix (bigint)

4. **RetirementScenario → Retirement**
   - Table: `retirement_scenarios` → `retirements`
   - Controller: `RetirementScenariosController` → `RetirementsController`
   - Routes: `retirement_scenarios_path` → `retirements_path`
   - Major structural changes: Age-based instead of date-based

### New Models Created
1. **Holding** - Represents individual positions in portfolio
2. **Price** - Time-series price data for holdings
3. **Trade** - Investment trades (buy/sell)
4. **Setting** - User settings/preferences
5. **Feedback** - User feedback/NPS scores
6. **Referral** - Referral tracking

### Updated Models

#### User
- Added: `referral_code`, `subscription_period`, `subscription_price_cents`, `stripe_customer_id`, `stripe_subscription_id`
- Relationships: `has_one :portfolio` (was `has_many`), `has_many :accounts` (was `savings_accounts`), `has_many :taxes`, `has_many :retirements`

#### Portfolio
- Now `has_one` per user (was `has_many`)
- Removed fields: `asset_type`, `ticker`, `purchase_date`, `purchase_price`, `quantity`, `status`
- Added relationship: `has_many :holdings`
- Fields moved to `Holding` model

#### Loan
- Field changes:
  - `principal` → `principal_cents` (bigint)
  - `interest_rate` → `rate_apr` (decimal)
  - Added: `rate_apy`, `start_date`, `end_date`, `periodic_payment_cents`, `current_period`, `current_balance_cents`
  - `payment_frequency` → `payment_period` (enum)
  - `compounding_period` (enum)

#### Tax
- Field changes (all monetary fields now cents):
  - `income` → `gross_income_cents`
  - `deductions` → `deductions_cents`
  - `taxable_income` → `taxable_income_cents`
  - `tax_paid` → `tax_paid_cents`
  - `refund` → `refund_cents`
  - Added: `payment_period` (enum)

#### Retirement
- Complete restructure:
  - Removed: `target_date`, `current_savings`, `monthly_contribution`, `target_amount`, `expected_return_rate`, `risk_level`
  - Added: `age_start`, `age_retirement`, `age_end`, `rate_inflation`, `rate_contribution_growth`, `rate_low`, `rate_mid`, `rate_high`, allocation fields (pre/post), `contribution_annual_cents`, `withdrawal_annual_pv_cents`, `withdrawal_rate_fv`
  - Compatibility methods added for backward compatibility with services

## Migration Files Created

1. `20250108000001_add_user_fields_from_data_model.rb` - User fields
2. `20250108000002_rename_savings_accounts_to_accounts.rb` - Rename table
3. `20250108000003_rename_monthly_snapshots_to_balances.rb` - Rename and restructure
4. `20250108000004_update_accounts_structure.rb` - Update account fields
5. `20250108000005_rename_tax_scenarios_to_taxes.rb` - Rename and convert to cents
6. `20250108000006_rename_retirement_scenarios_to_retirements.rb` - Rename and restructure
7. `20250108000007_update_loans_structure.rb` - Convert to cents and add fields
8. `20250108000008_create_holdings.rb` - New model
9. `20250108000009_create_prices.rb` - New model
10. `20250108000010_create_trades.rb` - New model
11. `20250108000011_create_settings.rb` - New model
12. `20250108000012_create_feedbacks.rb` - New model
13. `20250108000013_create_referrals.rb` - New model
14. `20250108000014_update_portfolio_structure.rb` - Remove old fields

## Controllers Updated

- `AccountsController` (new, replaces `SavingsAccountsController`)
- `BalancesController` (new, replaces `MonthlySnapshotsController`)
- `TaxesController` (new, replaces `TaxScenariosController`)
- `RetirementsController` (new, replaces `RetirementScenariosController`)
- `LoansController` - Updated params and field references
- `PortfoliosController` - Updated to work with Holdings
- `ExpensesController` - Updated redirects
- `SettingsController` - Updated export references

## Services Updated

- `NetWorthService` - Uses `accounts` and `balances`, cents conversion
- `SavingsChartDataService` - Updated to use `accounts` and `balances`
- `CashFlowChartDataService` - Updated to use `accounts` and `balances`
- `ExpensesChartDataService` - Updated to use `accounts` and `balances`
- `PortfolioValueService` - Updated to work with `portfolio` (has_one) and `holdings`
- `RetirementChartDataService` - Updated to use `retirements`
- `UserDataService` - Updated export/import for new model names
- `ExcelExportService` - Updated field references
- `PdfExportService` - Updated field references
- `InsuranceAnalysisService` - Updated to use `accounts` and `portfolio`

## Presenters Updated

- `PortfolioPresenter` - Updated for new Portfolio structure
- `RetirementPresenter` - New presenter for Retirement model
- `HoldingPresenter` - New presenter for Holding model

## Routes Updated

- `resources :savings_accounts` → `resources :accounts`
- `resources :tax_scenarios` → `resources :taxes`
- `resources :retirement_scenarios` → `resources :retirements`
- `resources :monthly_snapshots` → `resources :balances`

## Views That Need Manual Updates

The following view files still reference old model names/fields and should be updated:

1. `app/views/savings_accounts/index.html.erb` → Should be moved/renamed to `app/views/accounts/index.html.erb`
2. `app/views/savings_accounts/edit.html.erb` → Should be moved/renamed to `app/views/accounts/edit.html.erb`
3. `app/views/tax_scenarios/*.erb` → Should be moved/renamed to `app/views/taxes/*.erb`
4. `app/views/retirement_scenarios/*.erb` → Should be moved/renamed to `app/views/retirements/*.erb`
5. `app/views/portfolios/index.html.erb` - References old Portfolio fields
6. `app/views/portfolios/edit.html.erb` - References old Portfolio fields
7. `app/views/loans/index.html.erb` - Some field references updated, but form fields may need updates
8. `app/views/loans/_loans_overview_table.html.erb` - Field references updated

## Field Name Changes in Views

### Loan Fields
- `principal` → `principal_cents` (but model has `principal` method for compatibility)
- `interest_rate` → `rate_apr`
- Form fields should use `principal_cents` and `rate_apr`

### Tax Fields
- `income` → `gross_income_cents`
- `deductions` → `deductions_cents`
- `taxable_income` → `taxable_income_cents`
- `tax_paid` → `tax_paid_cents`
- `refund` → `refund_cents`
- Form fields should use `_cents` versions

### Account/Balance Fields
- `balance` → `amount_cents` (in Balance model)
- `recorded_at` → `balance_date`
- `position` → `index` (in Account model)
- Form fields should use new names

### Portfolio/Holding Fields
- Portfolio no longer has: `ticker`, `purchase_date`, `purchase_price`, `quantity`, `asset_type`, `status`
- These are now on `Holding` model
- Views should reference `@portfolio.holdings` instead of `@portfolios`

### Retirement Fields
- `target_date` → calculated from `age_start` and `age_retirement`
- `current_savings` → compatibility method (returns 0)
- `monthly_contribution` → compatibility method (from `contribution_annual_cents`)
- `target_amount` → compatibility method (calculated)
- `expected_return_rate` → compatibility method (returns `rate_mid`)

## Important Notes

1. **Cents Storage**: All monetary values are now stored as integers in cents. Models have helper methods to convert to/from dollars.

2. **Backward Compatibility**: Some models have compatibility methods to maintain functionality with existing services, but these should be updated over time.

3. **Data Migration**: The migrations include data transformation logic, but you may need to write custom data migration scripts if you have existing data.

4. **UUIDs**: The Excel specifies UUIDs for primary keys, but SQLite doesn't natively support UUIDs. The migrations use integer IDs. If you need UUIDs, you'll need to use string type or a UUID extension.

5. **Polymorphic Associations**: `MonthlySnapshot` was polymorphic (`snapshotable`). `Balance` is now a direct association to `Account` only.

6. **Portfolio Structure**: Portfolio is now `has_one` per user and contains `holdings`. The old structure had portfolios as individual positions.

## Next Steps

1. Run migrations: `rails db:migrate`
2. Update remaining view files (see list above)
3. Update form fields to use new field names
4. Test all functionality
5. Update any JavaScript that references old field names
6. Consider data migration scripts if you have existing data

