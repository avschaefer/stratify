# 🗺️ Financial Planner - Route & Navigation Diagram

## Application Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   Rails Application (7.1+)                  │
├─────────────────────────────────────────────────────────────┤
│  ✅ Authentication: DISABLED (All pages accessible)         │
│  ✅ Landing: http://localhost:3000/ → Dashboard             │
└─────────────────────────────────────────────────────────────┘
        │
        ├─── config/routes.rb
        │    ├─ root 'dashboard#index'
        │    └─ 7 Main Resource Routes
        │
        ├─── app/controllers/
        │    ├─ ApplicationController (no auth checks)
        │    └─ 9 Resource Controllers (no auth barriers)
        │
        └─── app/views/layouts/application.html.erb
             └─ Responsive Sidebar (7 navigation links)
```

---

## Request Flow Diagram

```
                    ┌──────────────────────────┐
                    │  Browser Request         │
                    │  http://localhost:3000/  │
                    └────────────┬─────────────┘
                                 │
                    ┌────────────▼─────────────┐
                    │  Rails Router            │
                    │  Matches: root route     │
                    └────────────┬─────────────┘
                                 │
                    ┌────────────▼──────────────────────┐
                    │  ApplicationController            │
                    │  ✅ No before_action filters      │
                    │  ✅ current_user = mock user      │
                    │  ✅ user_signed_in? = true        │
                    └────────────┬──────────────────────┘
                                 │
                    ┌────────────▼──────────────────────┐
                    │  DashboardController#index        │
                    │  Initializes @variables           │
                    └────────────┬──────────────────────┘
                                 │
                    ┌────────────▼──────────────────────┐
                    │  Render View                      │
                    │  app/views/dashboard/index.html   │
                    │  with application.html.erb        │
                    │  ✅ Sidebar rendered              │
                    │  ✅ Content displayed             │
                    └────────────┬──────────────────────┘
                                 │
                    ┌────────────▼──────────────────────┐
                    │  HTML Response to Browser         │
                    │  Status: 200 OK                   │
                    └──────────────────────────────────┘
```

---

## Navigation Hierarchy

```
Financial Planner Dashboard
│
├─ 🏠 Dashboard (/dashboard)
│   └─ Export functionality
│
├─ 📈 Portfolio (/portfolios)
│   ├─ List investments
│   ├─ Add new investment
│   ├─ Toggle status
│   └─ Delete investment
│
├─ 🏦 Savings & Expenses (/savings_accounts)
│   ├─ Savings Accounts
│   │  ├─ Add account
│   │  ├─ Edit account
│   │  └─ Monthly Snapshots (nested)
│   │
│   └─ Expenses
│      ├─ Add expense
│      ├─ Edit expense
│      └─ Monthly Snapshots (nested)
│
├─ 💳 Loans (/loans)
│   ├─ List loans
│   ├─ Add loan
│   ├─ Toggle status
│   ├─ Calculate payment
│   └─ Delete loan
│
├─ 🎯 Retirement (/retirement_scenarios)
│   ├─ Create scenario (max 5)
│   ├─ Calculate projection
│   ├─ Edit scenario
│   └─ Delete scenario
│
├─ 🛡️ Insurance (/insurance_policies)
│   ├─ List policies
│   ├─ Add policy
│   ├─ Toggle status
│   ├─ Calculate coverage
│   └─ Delete policy
│
└─ 📊 Taxes (/tax_scenarios)
    ├─ Create scenario
    ├─ Calculate tax
    ├─ Edit scenario
    └─ Delete scenario
```

---

## Route Definition Map

```
RESTful Routes (config/routes.rb)
│
├─── Dashboard Routes
│    └─ GET    /dashboard           → DashboardController#index
│    └─ GET    /dashboard/export    → DashboardController#export
│
├─── Portfolio Routes (Full CRUD)
│    ├─ GET    /portfolios           → PortfoliosController#index
│    ├─ POST   /portfolios           → PortfoliosController#create
│    ├─ PATCH  /portfolios/:id/toggle_status
│    └─ DELETE /portfolios/:id       → PortfoliosController#destroy
│
├─── Savings Routes (Full CRUD + Nested)
│    ├─ GET    /savings_accounts     → SavingsAccountsController#index
│    ├─ POST   /savings_accounts     → SavingsAccountsController#create
│    ├─ DELETE /savings_accounts/:id → SavingsAccountsController#destroy
│    └─ Nested Monthly Snapshots:
│        ├─ POST   /savings_accounts/:id/monthly_snapshots
│        ├─ PATCH  /savings_accounts/:id/monthly_snapshots/:id
│        └─ DELETE /savings_accounts/:id/monthly_snapshots/:id
│
├─── Loans Routes (Full CRUD + Actions)
│    ├─ GET    /loans                → LoansController#index
│    ├─ POST   /loans                → LoansController#create
│    ├─ POST   /loans/calculate      → LoansController#calculate
│    ├─ PATCH  /loans/:id/toggle_status
│    └─ DELETE /loans/:id            → LoansController#destroy
│
├─── Retirement Routes (Limited CRUD + Calculate)
│    ├─ GET    /retirement_scenarios → RetirementScenariosController#index
│    ├─ POST   /retirement_scenarios → RetirementScenariosController#create
│    ├─ POST   /retirement_scenarios/calculate
│    ├─ PATCH  /retirement_scenarios/:id
│    └─ DELETE /retirement_scenarios/:id
│
├─── Insurance Routes (Full CRUD + Actions)
│    ├─ GET    /insurance_policies   → InsurancePoliciesController#index
│    ├─ POST   /insurance_policies   → InsurancePoliciesController#create
│    ├─ POST   /insurance_policies/calculate
│    ├─ PATCH  /insurance_policies/:id/toggle_status
│    └─ DELETE /insurance_policies/:id
│
├─── Expense Routes (Full CRUD + Nested)
│    ├─ GET    /expenses             → ExpensesController#index
│    ├─ POST   /expenses             → ExpensesController#create
│    ├─ DELETE /expenses/:id         → ExpensesController#destroy
│    └─ Nested Monthly Snapshots
│
└─── Tax Routes (Limited CRUD + Calculate)
     ├─ GET    /tax_scenarios        → TaxScenariosController#index
     ├─ POST   /tax_scenarios        → TaxScenariosController#create
     ├─ POST   /tax_scenarios/calculate
     ├─ PATCH  /tax_scenarios/:id
     └─ DELETE /tax_scenarios/:id
```

---

## Authentication Flow (Currently Disabled)

```
┌─────────────────────────────────────────────────┐
│           Incoming Request                      │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
    ┌────────────────────────────┐
    │ ApplicationController      │
    │                            │
    │ ❌ NO before_action        │
    │    :authenticate_user!     │
    │                            │
    │ ✅ current_user method     │
    │    → returns mock user     │
    │    (demo@example.com)      │
    │                            │
    │ ✅ user_signed_in?         │
    │    → always returns true   │
    └────────────┬───────────────┘
                 │
                 ▼
    ┌────────────────────────────┐
    │ DeviseHelper               │
    │                            │
    │ ✅ authenticate_user!      │
    │    → NO-OP (empty)         │
    │                            │
    │ ✅ require_no_authentication
    │    → NO-OP (empty)         │
    │                            │
    │ ✅ user_signed_in?         │
    │    → always returns true   │
    └────────────┬───────────────┘
                 │
                 ▼
    ┌────────────────────────────┐
    │ ✅ REQUEST ALLOWED         │
    │                            │
    │ No redirects to login      │
    │ No 403 Forbidden errors    │
    │ No authentication barriers │
    └────────────────────────────┘
```

---

## Sidebar Navigation Component

```
┌────────────────────────────────────────────────────┐
│  Financial Planner (Logo)                          │
├────────────────────────────────────────────────────┤
│                                                    │
│  🏠 Dashboard       → link_to dashboard_index_path│
│  📈 Portfolio       → link_to portfolios_path     │
│  🏦 Savings & Exp   → link_to savings_accounts... │
│  💳 Loans          → link_to loans_path          │
│  🎯 Retirement     → link_to retirement_scenar...│
│  🛡️ Insurance      → link_to insurance_policies..│
│  📊 Taxes          → link_to tax_scenarios_path  │
│                                                    │
├────────────────────────────────────────────────────┤
│  Demo User         [Logout Button]                │
└────────────────────────────────────────────────────┘

Features:
✅ Fixed width: 260px
✅ Fixed position: left side, full height
✅ Active page highlight: CSS class 'active'
✅ Responsive: Hides on mobile (<768px)
✅ Bootstrap Icons: Each item has icon
✅ Error handling: begin/rescue prevents crashes
```

---

## Controller Inheritance Chain

```
Rails::ApplicationController (Rails framework)
           │
           ▼
ActionController::Base (Rails base)
           │
           ▼
ApplicationController ✅ (app/controllers/application_controller.rb)
│
├─ No before_action :authenticate_user!
├─ current_user helper (returns mock)
├─ user_signed_in? helper (returns true)
└─ helper_method declarations
           │
           ├─ DashboardController
           ├─ PortfoliosController
           ├─ SavingsAccountsController
           ├─ LoansController
           ├─ RetirementScenariosController
           ├─ InsurancePoliciesController
           ├─ TaxScenariosController
           ├─ ExpensesController
           └─ MonthlySnapshotsController
                           │
                           ▼
                    ✅ ALL inherit ApplicationController
                       with NO auth barriers
```

---

## Status Summary

```
┌────────────────────────────────────────────────────────────┐
│           ✅ VERIFICATION COMPLETE                         │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  Landing Page      ✅  root 'dashboard#index'              │
│  Routes Defined    ✅  7 main sections + actions           │
│  Navigation Links  ✅  All 7 items in sidebar              │
│  Authentication    ✅  COMPLETELY DISABLED                │
│  Access Control    ✅  NO barriers to any page             │
│  Forms             ✅  All submission routes working       │
│  Response Design   ✅  Mobile-friendly sidebar             │
│                                                             │
│  🎯 READY FOR UI/UX TESTING                              │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

---

## Quick Reference: URL Mapping

| What | URL | Controller | Status |
|-----|-----|-----------|--------|
| Home | `localhost:3000/` | Dashboard | ✅ |
| Dashboard | `localhost:3000/dashboard` | Dashboard | ✅ |
| Portfolio | `localhost:3000/portfolios` | Portfolios | ✅ |
| Savings | `localhost:3000/savings_accounts` | SavingsAccounts | ✅ |
| Loans | `localhost:3000/loans` | Loans | ✅ |
| Retirement | `localhost:3000/retirement_scenarios` | RetirementScenarios | ✅ |
| Insurance | `localhost:3000/insurance_policies` | InsurancePolicies | ✅ |
| Taxes | `localhost:3000/tax_scenarios` | TaxScenarios | ✅ |

---

Last Updated: November 4, 2025
