# Financial Planner - Setup Instructions

## Prerequisites

1. Ruby 3.2.0 or higher
2. Rails 7.1 or higher
3. SQLite3
4. Node.js (for JavaScript dependencies)

## Installation Steps

1. **Install Ruby dependencies:**
   ```bash
   bundle install
   ```

2. **Set up the database:**
   ```bash
   rails db:create
   rails db:migrate
   ```

3. **Start the Rails server:**
   ```bash
   rails server
   ```

4. **Access the application:**
   - Open your browser to http://localhost:3000
   - Sign up for a new account
   - Start adding your financial data

## Features Implemented

### ✅ Authentication
- User sign up and login using Devise
- Password reset functionality

### ✅ Dashboard
- Financial overview with totals (Assets, Liabilities, Net Worth)
- Asset allocation pie chart (Chart.js)
- Monthly trends line chart
- Export buttons (Excel/PDF placeholders)

### ✅ Portfolio
- Add investments (stocks, bonds, crypto, other)
- Track ticker, purchase date, price, quantity
- Draft/Active status toggle
- View total value calculations

### ✅ Savings & Expenses
- Manage savings accounts (Savings, Checking, Credit Card)
- Add expense categories
- Monthly snapshot tracking for balances
- Historical trend display

### ✅ Loans
- Loan calculator (principal, rate, term)
- Save loan scenarios
- Monthly payment and interest calculations
- Draft/Active status toggle

### ✅ Retirement
- Scenario calculator (up to 5 scenarios)
- Target date, contributions, expected returns
- Progress bars showing projected vs target
- Risk level selection

### ✅ Insurance
- Policy tracking (Life, Health, Auto, Home)
- Premium calculations
- Coverage amount tracking
- Draft/Active status toggle

### ✅ Taxes
- Tax estimator calculator
- 2024 tax bracket calculations
- After-tax income estimates
- Save multiple scenarios

## UI Design

The application follows the v0 Vercel design with:
- Left sidebar navigation
- Professional teal/blue color scheme
- Clean, modern interface suitable for mature users
- Responsive design (mobile-friendly)
- Bootstrap 5 for styling
- Chart.js for data visualization

## Database Schema

- Users (Devise)
- Portfolios
- Savings Accounts
- Expenses
- Monthly Snapshots (polymorphic)
- Loans
- Retirement Scenarios
- Insurance Policies
- Tax Scenarios

## Next Steps (Future Enhancements)

1. Implement Excel/PDF export functionality
2. Add data import capabilities
3. Enhanced chart visualizations
4. Email notifications for reminders
5. Advanced reporting features

