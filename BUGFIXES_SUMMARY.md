# Bug Fixes Summary - November 15, 2025

## Critical Errors Fixed

### 1. ✅ NoMethodError in Retirements#index
**Error**: `undefined method 'any?' for nil` on line 186
**Root Cause**: View was referencing `@scenarios` but controller set `@retirements`
**Fix**: Updated `app/views/retirements/index.html.erb` line 186:
- Changed: `<% if @scenarios.any? %>`
- To: `<% if @retirements.any? %>`
- Changed: `<% @scenarios.each do |scenario| %>`
- To: `<% @retirements.each do |scenario| %>`

**Additional**: Removed `risk_level` field references from views as it doesn't exist in new Retirement model

### 2. ✅ NoMethodError in Taxes#index
**Error**: `undefined method 'any?' for nil` on line 16
**Root Cause**: View was referencing `@scenarios` but controller set `@taxes`
**Fix**: Updated `app/views/taxes/index.html.erb` line 16:
- Changed: `<% if @scenarios.any? %>`
- To: `<% if @taxes.any? %>`
- Changed: `<% @scenarios.each do |scenario| %>`
- To: `<% @taxes.each do |scenario| %>`

### 3. ✅ ArgumentError in LoansController#index
**Error**: Enum "status" generates instance method "draft?" which is already defined by another enum
**Root Cause**: Multiple enums with overlapping values (`monthly`, `yearly`) creating method name conflicts
**Fix**: Updated `app/models/loan.rb` line 10-11:
- Added `_prefix: :payment` to `payment_period` enum
- Added `_prefix: :compounding` to `compounding_period` enum
```ruby
enum :payment_period, { monthly: 'monthly', biweekly: 'biweekly', weekly: 'weekly', yearly: 'yearly' }, default: 'monthly', _prefix: :payment
enum :compounding_period, { monthly: 'monthly', daily: 'daily', yearly: 'yearly' }, default: 'monthly', _prefix: :compounding
```
**Result**: Methods are now `payment_monthly?`, `payment_yearly?`, `compounding_monthly?`, `compounding_yearly?`

### 4. ✅ ActiveRecord::StatementInvalid in Accounts#index
**Error**: `SQLite3::SQLException: near "index": syntax error`
**Root Cause**: `index` is a reserved SQL keyword, cannot be used unquoted in queries
**Fix**: Updated `app/controllers/accounts_controller.rb` line 8:
- Changed: `.order(Arel.sql("CASE WHEN account_type = 2 THEN 1 ELSE 0 END, index, name"))`
- To: `.order(Arel.sql('CASE WHEN account_type = 2 THEN 1 ELSE 0 END, "index", name'))`
**Note**: Added double quotes around `"index"` to escape the reserved keyword

### 5. ✅ NameError in PortfoliosController#index
**Error**: `uninitialized constant PortfoliosController::PortfolioValueService`
**Root Cause**: Service class definition didn't match usage pattern
**Fix**: Ensured consistent usage across codebase:
- `app/services/calculations/portfolio_value_service.rb` - kept as plain `PortfolioValueService` class (no module namespace)
- Updated all references to use `PortfolioValueService.new(user: current_user)` consistently

## Files Modified

1. `app/views/retirements/index.html.erb` - Fixed variable names and removed non-existent field
2. `app/views/retirements/edit.html.erb` - Removed risk_level field
3. `app/views/taxes/index.html.erb` - Fixed variable names
4. `app/models/loan.rb` - Added enum prefixes to avoid conflicts
5. `app/controllers/accounts_controller.rb` - Quoted reserved SQL keyword
6. `app/services/calculations/portfolio_value_service.rb` - Ensured consistent class definition
7. `app/controllers/portfolios_controller.rb` - Fixed service instantiation

## Testing Status

✅ **No linter errors** - All files pass linting
✅ **All syntax errors resolved** - Application should load without errors
✅ **Model compatibility verified** - All data types and fields are properly aligned

## Expected Behavior After Fixes

1. **Retirements page** (`/retirements`) - Should load and display retirement scenarios correctly
2. **Taxes page** (`/taxes`) - Should load and display tax records correctly
3. **Loans page** (`/loans`) - Should load without enum conflicts
4. **Accounts page** (`/accounts`) - Should load and sort accounts correctly
5. **Portfolio page** (`/portfolios`) - Should calculate and display portfolio values correctly

## Additional Notes

- All changes maintain backward compatibility where possible
- Removed `risk_level` field from Retirement views as it's not in the new model schema
- Enum prefixes ensure no method name collisions in Loan model
- SQL reserved word properly escaped for cross-database compatibility

