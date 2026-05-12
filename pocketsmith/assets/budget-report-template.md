# Budget vs Actual Report: {{PERIOD_LABEL}}

**Period:** {{START_DATE}} to {{END_DATE}}  
**Generated:** {{GENERATED_AT}}  
**Currency:** {{CURRENCY_CODE}}  
**Days remaining in period:** {{DAYS_REMAINING}}

---

## Summary

| Metric | Amount |
|--------|--------|
| Total Budgeted (Expenses) | {{TOTAL_BUDGET_EXPENSES}} |
| Total Actual (Expenses) | {{TOTAL_ACTUAL_EXPENSES}} |
| Overall Variance | {{OVERALL_VARIANCE}} ({{OVERALL_VARIANCE_PCT}}%) |
| Total Budgeted (Income) | {{TOTAL_BUDGET_INCOME}} |
| Total Actual (Income) | {{TOTAL_ACTUAL_INCOME}} |
| Net Savings Rate | {{SAVINGS_RATE}}% |

**Overall budget status:** {{OVERALL_STATUS}} <!-- ON TRACK / OVER BUDGET / UNDER BUDGET -->

---

## Expenses — Budget vs Actual

| Category | Budgeted | Actual | Variance | % Used | Status |
|----------|:--------:|:------:|:--------:|:------:|:------:|
| {{CAT_1_NAME}} | {{CAT_1_BUDGET}} | {{CAT_1_ACTUAL}} | {{CAT_1_VARIANCE}} | {{CAT_1_PCT}}% | {{CAT_1_STATUS}} |
| {{CAT_2_NAME}} | {{CAT_2_BUDGET}} | {{CAT_2_ACTUAL}} | {{CAT_2_VARIANCE}} | {{CAT_2_PCT}}% | {{CAT_2_STATUS}} |
| {{CAT_3_NAME}} | {{CAT_3_BUDGET}} | {{CAT_3_ACTUAL}} | {{CAT_3_VARIANCE}} | {{CAT_3_PCT}}% | {{CAT_3_STATUS}} |
| {{CAT_4_NAME}} | {{CAT_4_BUDGET}} | {{CAT_4_ACTUAL}} | {{CAT_4_VARIANCE}} | {{CAT_4_PCT}}% | {{CAT_4_STATUS}} |
| {{CAT_5_NAME}} | {{CAT_5_BUDGET}} | {{CAT_5_ACTUAL}} | {{CAT_5_VARIANCE}} | {{CAT_5_PCT}}% | {{CAT_5_STATUS}} |
| {{CAT_6_NAME}} | {{CAT_6_BUDGET}} | {{CAT_6_ACTUAL}} | {{CAT_6_VARIANCE}} | {{CAT_6_PCT}}% | {{CAT_6_STATUS}} |
| {{CAT_7_NAME}} | {{CAT_7_BUDGET}} | {{CAT_7_ACTUAL}} | {{CAT_7_VARIANCE}} | {{CAT_7_PCT}}% | {{CAT_7_STATUS}} |
| {{CAT_8_NAME}} | {{CAT_8_BUDGET}} | {{CAT_8_ACTUAL}} | {{CAT_8_VARIANCE}} | {{CAT_8_PCT}}% | {{CAT_8_STATUS}} |
| **Total** | **{{TOTAL_BUDGET_EXPENSES}}** | **{{TOTAL_ACTUAL_EXPENSES}}** | **{{OVERALL_VARIANCE}}** | **{{OVERALL_PCT}}%** | **{{OVERALL_STATUS}}** |

**Status key:** ✅ On Track &nbsp;|&nbsp; ⚠️ Approaching Limit &nbsp;|&nbsp; 🔴 Over Budget &nbsp;|&nbsp; 💚 Under Budget

---

## Income — Budget vs Actual

| Category | Budgeted | Actual | Variance | % Received |
|----------|:--------:|:------:|:--------:|:----------:|
| {{INC_1_NAME}} | {{INC_1_BUDGET}} | {{INC_1_ACTUAL}} | {{INC_1_VARIANCE}} | {{INC_1_PCT}}% |
| {{INC_2_NAME}} | {{INC_2_BUDGET}} | {{INC_2_ACTUAL}} | {{INC_2_VARIANCE}} | {{INC_2_PCT}}% |
| **Total** | **{{TOTAL_BUDGET_INCOME}}** | **{{TOTAL_ACTUAL_INCOME}}** | **{{INCOME_VARIANCE}}** | **{{INCOME_PCT}}%** |

---

## Variance Analysis

### Over Budget Categories
{{#if OVER_BUDGET_CATEGORIES}}
| Category | Over by | % Over |
|----------|:-------:|:------:|
{{OVER_BUDGET_ROWS}}
{{else}}
*No categories are currently over budget.* ✅
{{/if}}

### Highest Underspend
| Category | Under by | % Remaining |
|----------|:--------:|:-----------:|
{{UNDERSPEND_ROWS}}

---

## Pace Analysis

Based on {{DAYS_ELAPSED}} of {{DAYS_IN_PERIOD}} days elapsed ({{PACE_PCT}}% through the period):

| Metric | Expected at Pace | Actual | Status |
|--------|:---------------:|:------:|:------:|
| Total Expenses | {{EXPECTED_EXPENSES}} | {{TOTAL_ACTUAL_EXPENSES}} | {{PACE_STATUS}} |
| Total Income | {{EXPECTED_INCOME}} | {{TOTAL_ACTUAL_INCOME}} | {{INCOME_PACE_STATUS}} |

---

## Recommendations

- {{RECOMMENDATION_1}}
- {{RECOMMENDATION_2}}
- {{RECOMMENDATION_3}}

---

## Notes

- Amounts in {{CURRENCY_CODE}}. Transfers excluded.
- "Status" uses 90% threshold for ⚠️ Approaching Limit.
- Data source: PocketSmith API v2 — `/users/{{USER_ID}}/budget-summary`
