# Next Steps - Financial Planner Application

## Current Status
✅ All core functionality from Phase 1-5 has been implemented:
- Export functionality (Excel/PDF)
- Active Storage configuration
- Missing controller actions (most CRUD operations)
- Form fixes and data integration
- Chart data using real user data

## Remaining Tasks

### 1. Missing Edit/Update Functionality
Several resources are missing edit/update actions and views:

#### Priority 1: High - Broken Delete Links
- **Insurance Policies**: Delete link points to `#` instead of actual route
- **Loans**: Delete link points to `#` instead of actual route
- **Action**: Fix delete links to use proper routes

#### Priority 2: Medium - Missing Edit/Update Actions
- **Insurance Policies**: No edit/update actions or view
- **Loans**: No edit/update actions or view  
- **Savings Accounts**: No edit/update actions or view
- **Action**: Add edit/update actions and views following the pattern used for portfolios/retirement_scenarios

#### Priority 3: Minor - Route Fixes
- **Retirement Scenarios**: Routes only include `:index, :create, :update, :destroy` but missing `:edit` (needed for update action)
- **Action**: Add `:edit` to retirement_scenarios routes (or use `resources :retirement_scenarios` without restrictions)

### 2. Settings Page Enhancements
- **Data Export History**: Display list of previously exported files
- **Action**: Add view to show `@data_files` attachment list with download links

### 3. Database Schema Considerations
- **Retirement Scenario**: `yearly_withdrawal` field may not exist in database
  - Check if migration needed
  - If field doesn't exist, either add migration or remove references

### 4. Testing & Validation
- **Form Validations**: Ensure all forms have proper validation
- **Error Handling**: Test error scenarios (invalid data, missing fields, etc.)
- **Permission Checks**: Verify all actions properly check user ownership

### 5. UI/UX Improvements
- **Empty States**: Ensure all pages have proper empty state messages
- **Loading States**: Add loading indicators for async operations
- **Success Messages**: Verify flash messages display correctly
- **Delete Confirmations**: Ensure all delete actions have confirmation dialogs

### 6. Data Integrity
- **Monthly Snapshots**: Ensure snapshots can only be created/updated for correct months
- **Status Fields**: Verify status enums work correctly (portfolio, loan, insurance policy)
- **Date Validations**: Ensure dates are validated (future dates for retirement scenarios, etc.)

## Recommended Implementation Order

1. **Fix broken delete links** (Insurance Policies, Loans) - Quick fix
2. **Add edit/update for Insurance Policies** - Users need to modify policies
3. **Add edit/update for Loans** - Users need to modify loans
4. **Add edit/update for Savings Accounts** - Users need to modify account details
5. **Fix retirement_scenarios routes** - Add `:edit` or remove restrictions
6. **Add data export history to settings** - Show previous exports
7. **Check and fix yearly_withdrawal field** - Database consistency
8. **Test all CRUD operations** - Ensure everything works end-to-end

## Notes
- All new edit views should follow the pattern established in `portfolios/edit.html.erb` and `retirement_scenarios/edit.html.erb`
- All edit actions should include proper authorization checks
- Forms should pre-populate with existing data
- Error handling should display validation errors clearly

