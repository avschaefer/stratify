<!-- d66062e3-fa9e-4d2a-b52c-9232f2609667 a9249ae0-6ee0-469a-a1eb-9caf8d383f40 -->
# Plan: Refine UI and Standardize Components

## 1. UI Standardization (Global)

- **Objective**: Enforce consistent styling for buttons, inputs, and modals across the application.
- **Files**: `app/assets/stylesheets/application.tailwind.css` (create if needed, or add to layout head styles), `app/views/layouts/application.html.erb`.
- **Actions**:
- Define standard CSS classes:
- `.btn-primary`: Black background, white text, rounded-full (pill).
- `.btn-secondary`: White background, border-gray-200, text-gray-900, rounded-full.
- `.btn-danger`: Red background/text style as appropriate (likely outlined or light bg).
- `.input-standard`: White background, gray border, focus:ring-1 focus:ring-black focus:border-black.
- Update `application.html.erb` to include these styles if not using a build process for CSS.

## 2. Dashboard Refinement (`/dashboard`)

- **Files**: `app/views/dashboard/index.html.erb`, `app/javascript/controllers/dashboard_charts_controller.js`
- **Actions**:
- **Charts Layout**: Reorder charts to:

1.  Net Worth Growth (Line/Area) - Full width.
2.  Asset Allocation (Bar Chart - formerly Pie) - Full width (or large).
3.  Monthly Cash Flow (Bar Chart) - Full width.

- **Chart Type**: Change Asset Allocation from Pie/Doughnut to Horizontal Bar Chart.
- **Toggles**: Replace the Net Worth "Select" dropdown with a button group (`1M`, `3M`, `6M`, `1Y`, `ALL`) matching the Portfolio page.
- **Cash Flow**: Ensure the Cash Flow chart visual matches the Savings page request (Green/Red bars).

## 3. Portfolio Refinement (`/portfolios`)

- **Files**: `app/views/portfolios/index.html.erb`
- **Actions**:
- **Action Buttons**: Add "Add Trade" and "Add Holding" buttons to the Holdings table header (next to "Update Prices").
- **Styling**: Apply standardized button classes.

## 4. Accounts Refinement (`/accounts`)

- **Files**: `app/views/accounts/index.html.erb`, `app/javascript/controllers/accounts_charts_controller.js`
- **Actions**:
- **Chart**: Update "Net Savings Cash Flow" chart to match the Dashboard Cash Flow chart's visual style (colors, tooltips, bar shape).
- **Edit Actions**: Split the single "Edit" action into two distinct options for each account row:

1.  "Edit Info" (Account name, type, etc.)
2.  "Edit Balances" (Monthly balance history)

- *Implementation*: Use two small icon buttons or a clear text split.

## 5. Modal Standardization

- **Files**: `app/views/shared/_modal.html.erb` (Create), `app/views/insurance_policies/index.html.erb`, `app/views/taxes/index.html.erb`, `app/views/retirements/index.html.erb`, `app/views/accounts/index.html.erb` (and modals), `app/views/loans/index.html.erb` (and modals)
- **Actions**:
- Create a reusable Modal partial (`shared/modal`) or enforce a strict HTML structure for all `<dialog>` elements.
- **Style**: White background, rounded-2xl, backdrop-blur, standardized header with "X" close button, standardized footer buttons.
- Update all existing views (Insurance, Taxes, Retirement) to use this consistent modal structure.
- Implement new modals for Accounts (Info & Balances) and Loans (if applicable) using this style.

## 6. Input Field Styling

- **Files**: All views with forms.
- **Actions**:
- Apply the `.input-standard` class (or equivalent Tailwind utility string) to all text inputs, selects, and textareas.
- `focus:ring-1 focus:ring-black focus:border-black bg-white`.

## Dependencies

- **Chart.js**: Adjust config for Asset Allocation bar chart.
- **Tailwind**: Use arbitrary values or config for specific focus rings if needed.

### To-dos

- [ ] Clean up Layout and Create Sidebar Helpers (NO ICONS IN ENTIRE APP)
- [ ] Implement Dashboard View and Charts
- [ ] Implement Portfolio View and Charts
- [ ] Implement Accounts and Loans Views
- [ ] Implement Secondary Views (Insurance, Taxes, Retirement, Settings)