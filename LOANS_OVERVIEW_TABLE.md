# Loans Overview Table - Implementation Guide

## Overview

A new comprehensive loans overview table has been added above the individual loan cards on the loans index page. This table provides a compact, visual representation of all loans with a focus on progress tracking and time remaining.

## Features

### 1. **Progress Bars (Primary UI Element)**
   - **Principal Paid Progress Bar** (Blue gradient: #3b82f6 → #60a5fa)
     - Shows percentage of principal paid down (0-100%)
     - Displays percentage text when > 10% filled
     - Uses placeholder data (will be updated when payment records are added)
   
   - **Interest Paid Progress Bar** (Red gradient: #ef4444 → #f87171)
     - Shows percentage of interest paid down (0-100%)
     - Displays percentage text when > 10% filled
     - Uses placeholder data (will be updated when payment records are added)

### 2. **Period Tracker (Secondary UI Element)**
   - Compact badge showing: `X periods / Total periods`
   - Example: `12 / 360` (12 periods paid of 360 total)
   - Calculated based on 12 months per year by default

### 3. **Time Remaining (Large Display)**
   - **Primary Display**: Years remaining in large text (1.5rem, 700 weight)
   - Blue accent color (#60a5fa) for emphasis
   - Label: "years left" in small uppercase text
   - Example: "4.5 years left"

### 4. **Loan Information Column**
   - Loan name (bold, primary color)
   - Principal amount in light gray
   - All loans listed in table rows

## Data Structure

The following methods were added to the `Loan` model:

```ruby
# Data methods (placeholders - will be populated from payment records)
def principal_paid
  # Placeholder: 0 until payment records are implemented
  0
end

def interest_paid
  # Placeholder: 0 until payment records are implemented
  0
end

# Calculated metrics
def principal_paid_percentage
  # Returns 0-100 percentage of principal paid
  ((principal_paid.to_f / principal) * 100).clamp(0, 100).round(1)
end

def interest_paid_percentage
  # Returns 0-100 percentage of interest paid
  ((interest_paid.to_f / total_interest) * 100).clamp(0, 100).round(1)
end

def periods_paid
  # Placeholder: 0 until payment records are implemented
  0
end

def total_periods
  # Calculated: months in loan term (12 * years)
  (term_years * 12).to_i
end

def years_remaining
  # Calculated: remaining time in years
  remaining_periods = total_periods - periods_paid
  (remaining_periods.to_f / 12).round(1)
end
```

## Usage

The overview table is automatically rendered in `/app/views/loans/index.html.erb`:

```erb
<%= render 'loans_overview_table', loans: @loans %>
```

The partial is located at: `/app/views/loans/_loans_overview_table.html.erb`

## Styling

- **Responsive Design**: Table adapts to mobile screens with reduced padding and font sizes
- **Dark Theme**: Matches the existing dark mode design
- **Hover Effects**: Subtle background color change on row hover
- **Compact View**: Optimized for displaying multiple loans without excessive vertical space

### Color Scheme
- Principal Progress: Blue gradient (#3b82f6 → #60a5fa)
- Interest Progress: Red gradient (#ef4444 → #f87171)
- Time Remaining: Blue accent (#60a5fa)
- Border/Separators: rgba(255, 255, 255, 0.05) - 0.1)
- Text: #fafafa (primary), #a3a3a3 (secondary)

## Next Steps - Data Integration

When you're ready to add payment tracking, follow these steps:

1. **Create Payment Records Model**
   ```ruby
   # db/migrate/xxx_create_loan_payments.rb
   create_table :loan_payments do |t|
     t.references :loan, foreign_key: true
     t.decimal :principal_paid, precision: 10, scale: 2
     t.decimal :interest_paid, precision: 10, scale: 2
     t.integer :period_number
     t.decimal :remaining_balance, precision: 10, scale: 2
     t.datetime :payment_date
     t.timestamps
   end
   ```

2. **Update Loan Model Methods**
   ```ruby
   def principal_paid
     loan_payments.sum(:principal_paid)
   end

   def interest_paid
     loan_payments.sum(:interest_paid)
   end

   def periods_paid
     loan_payments.count
   end
   ```

3. **The rest of the calculation methods will automatically work**
   - `principal_paid_percentage` will update automatically
   - `interest_paid_percentage` will update automatically
   - `years_remaining` will calculate correctly

## Features Implemented

✅ Loans overview table with compact layout
✅ Two progress bars (principal and interest paid)
✅ Period tracker (x periods / total periods)
✅ Large time remaining display
✅ Responsive mobile design
✅ Dark theme consistent with app
✅ Placeholder methods ready for data integration
✅ Hover effects and visual feedback
✅ Percentage display in progress bars
✅ Color-coded progress bars (blue for principal, red for interest)

## Files Modified

- `/app/models/loan.rb` - Added progress tracking methods
- `/app/views/loans/index.html.erb` - Added table render call
- `/app/views/loans/_loans_overview_table.html.erb` - New partial for table display

## Visual Layout

```
┌─ Loan Name          ┌─ Principal Paid ─┐  ┌─ Interest Paid ──┐  ┌─ Period ─┐  ┌─ Years ──┐
│ Principal Amount    │   |████░░░░| 40%  │  │ |██░░░░░░░| 15%  │  │ 12 / 360 │  │   4.5     │
│                     └─────────────────┘  └──────────────────┘  │ periods  │  │ years    │
│                                                                │          │  │   left    │
└─────────────────────────────────────────────────────────────────┴──────────┴──┴──────────┘
```

---

All loans from the database are displayed in this table format above the individual card view, providing a quick overview of your loan portfolio's progress.

