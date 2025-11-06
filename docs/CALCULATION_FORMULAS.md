# Calculation Formulas Documentation

This document describes all financial calculation formulas used in the application and their sources.

## Loan Calculations

### Amortization Formula

The periodic payment for a loan is calculated using the standard amortization formula:

```
P = PV * (r * (1 + r)^n) / ((1 + r)^n - 1)
```

Where:
- `P` = Periodic payment
- `PV` = Present value (principal)
- `r` = Periodic interest rate (annual rate / periods per year)
- `n` = Total number of payments (years * periods per year)

**Source**: Standard financial mathematics, commonly used in mortgage and loan calculations.

### APR/APY Conversion

**APR to APY:**
```
APY = (1 + APR/n)^n - 1
```

**APY to APR:**
```
APR = n * (((1 + APY)^(1/n)) - 1)
```

Where `n` is the number of compounding periods per year.

**Source**: Financial Industry Regulatory Authority (FINRA) standards.

### Effective Annual Rate

For loans with different payment and compounding frequencies:

```
EAR = ((1 + r)^(compounding_per_year / payment_per_year) - 1) * payment_per_year
```

## Retirement Projections

### Future Value with Contributions

The future value of savings with regular contributions:

```
FV = PV * (1 + r)^n + PMT * (((1 + r)^n - 1) / r)
```

Where:
- `FV` = Future value
- `PV` = Present value (current savings)
- `PMT` = Periodic contribution
- `r` = Periodic interest rate (annual rate / 12)
- `n` = Number of periods (months)

**Source**: Standard compound interest formula with annuity payments.

### Required Monthly Contribution

To reach a target amount:

```
PMT = (FV - PV * (1 + r)^n) * r / ((1 + r)^n - 1)
```

This calculates the monthly contribution needed to reach the target future value.

**Source**: Rearranged future value formula.

### Withdrawal Phase

During retirement, the remaining balance after withdrawals:

```
Balance = Previous_Balance * (1 + r) - Withdrawal
```

This model assumes constant monthly withdrawals and investment returns.

## Tax Calculations

### Progressive Tax Brackets (2024 Federal)

The tax calculation uses progressive brackets where each portion of income is taxed at its respective rate:

1. 10% on income from $0 to $11,000
2. 12% on income from $11,001 to $44,725
3. 22% on income from $44,726 to $95,350
4. 24% on income from $95,351 to $201,050
5. 32% on income from $201,051 to $502,300
6. 37% on income above $502,300

**Taxable Income:**
```
Taxable Income = Income - Deductions
```

**Estimated Tax:**
Tax is calculated progressively, applying each bracket rate only to the portion of income within that bracket.

**Source**: IRS 2024 Tax Brackets (filing status: Single)

### Effective Tax Rate

```
Effective Rate = (Total Tax / Total Income) * 100
```

This represents the average tax rate paid on total income.

## Net Worth Calculations

### Total Assets

```
Total Assets = Portfolio Value + Savings Accounts Balance
```

Where:
- Portfolio Value = Sum of (purchase_price * quantity) for all portfolios
- Savings Balance = Sum of current month's snapshots for all savings accounts

### Total Liabilities

```
Total Liabilities = Sum of all loan principals
```

### Net Worth

```
Net Worth = Total Assets - Total Liabilities
```

### Monthly Savings

```
Monthly Savings = Current Month Savings - Previous Month Savings
```

## Portfolio Calculations

### Portfolio Value

```
Portfolio Value = Purchase Price * Quantity
```

### Asset Allocation

```
Allocation Percentage = (Asset Type Value / Total Portfolio Value) * 100
```

## Insurance Analysis

### Cost per $1,000 of Coverage

```
Cost per $1,000 = (Annual Premium / Coverage Amount) * 1,000
```

### Coverage Adequacy

```
Adequacy Percentage = (Current Coverage / Suggested Coverage) * 100
```

### Suggested Coverage (Life Insurance)

```
Suggested Coverage = Total Assets * 2
```

This follows the general rule of thumb that life insurance should cover 2x annual income or assets.

**Source**: General financial planning guidelines.

## Monthly Trends

Monthly trends are calculated by:
1. Retrieving historical snapshots for each month
2. Calculating assets (portfolio + savings) for each month
3. Calculating liabilities (using current loans as proxy)
4. Calculating net worth (assets - liabilities)

Note: Historical portfolio values are approximated using current values. For accurate historical tracking, portfolio snapshots should be implemented.

## Limitations and Notes

1. **Tax Calculations**: Current implementation uses simplified progressive brackets. Actual IRS calculations may differ slightly due to rounding and other factors.

2. **Loan Amortization**: The calculation assumes fixed interest rates and equal periodic payments. Variable rate loans require different formulas.

3. **Retirement Projections**: Assumes constant return rates and contributions. Real-world returns and contributions will vary.

4. **Historical Data**: Portfolio value history uses current values as proxy. For accurate historical tracking, implement portfolio snapshots.

5. **Insurance Suggestions**: Generic formulas used. Actual coverage needs vary by individual circumstances.

6. **Currency**: All calculations assume USD. Multi-currency support requires conversion rates.

## References

- Investopedia: Loan Amortization Formulas
- IRS: 2024 Tax Brackets and Rates
- FINRA: APR vs APY Calculations
- Standard Financial Mathematics Textbooks
- General Financial Planning Guidelines

