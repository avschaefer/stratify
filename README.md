# README

# Financial Planner - Rails MVP

A simple financial planning web application built with Ruby on Rails for low-frequency financial tracking.

## Features

- User Authentication (Devise)
- Dashboard with financial overview
- Portfolio tracking (stocks, bonds, crypto)
- Savings & Expenses tracking with monthly snapshots
- Loan calculator and tracking
- Retirement scenario planning (up to 5 scenarios)
- Insurance policy tracking
- Tax estimation calculator

## Setup

1. Install Ruby (3.2.0 or higher) and Rails 7.1+
2. Install dependencies:
   ```bash
   bundle install
   ```

3. Set up the database:
   ```bash
   rails db:create
   rails db:migrate
   ```

4. Start the server:
   ```bash
   rails server
   ```

5. Visit http://localhost:3000

## Architecture

- **Backend**: Ruby on Rails 7.1
- **Database**: SQLite (development)
- **Authentication**: Devise
- **Frontend**: Bootstrap 5 with custom CSS
- **Charts**: Chart.js

## Usage

1. Sign up for an account
2. Navigate through the sidebar to add financial data
3. Use calculators to explore scenarios (save as "Draft")
4. Mark items as "Active" to include them in dashboard totals
5. Export your financial snapshot from the Dashboard

## Notes

- All data is manual entry (no bank API integrations)
- Draft vs Active status allows for scenario planning
- Monthly snapshots track historical balances
- Maximum 5 retirement scenarios per user

# Ryzon
