# Spending Report: {{PERIOD_LABEL}}

**Period:** {{START_DATE}} to {{END_DATE}}  
**Generated:** {{GENERATED_AT}}  
**Currency:** {{CURRENCY_CODE}}

---

## Summary

| Metric | Value |
|--------|-------|
| Total Spending | {{TOTAL_SPENDING}} |
| Number of Transactions | {{TRANSACTION_COUNT}} |
| Average Transaction | {{AVG_TRANSACTION}} |
| Largest Single Expense | {{MAX_TRANSACTION}} ({{MAX_PAYEE}}) |
| Categories with Spending | {{CATEGORY_COUNT}} |

---

## Spending by Category

| # | Category | Amount | % of Total | Transactions |
|---|----------|--------|:----------:|:------------:|
| 1 | {{CATEGORY_1_NAME}} | {{CATEGORY_1_AMOUNT}} | {{CATEGORY_1_PCT}}% | {{CATEGORY_1_TXN_COUNT}} |
| 2 | {{CATEGORY_2_NAME}} | {{CATEGORY_2_AMOUNT}} | {{CATEGORY_2_PCT}}% | {{CATEGORY_2_TXN_COUNT}} |
| 3 | {{CATEGORY_3_NAME}} | {{CATEGORY_3_AMOUNT}} | {{CATEGORY_3_PCT}}% | {{CATEGORY_3_TXN_COUNT}} |
| 4 | {{CATEGORY_4_NAME}} | {{CATEGORY_4_AMOUNT}} | {{CATEGORY_4_PCT}}% | {{CATEGORY_4_TXN_COUNT}} |
| 5 | {{CATEGORY_5_NAME}} | {{CATEGORY_5_AMOUNT}} | {{CATEGORY_5_PCT}}% | {{CATEGORY_5_TXN_COUNT}} |
| — | *(other)* | {{OTHER_AMOUNT}} | {{OTHER_PCT}}% | {{OTHER_TXN_COUNT}} |
| | **Total** | **{{TOTAL_SPENDING}}** | **100%** | **{{TRANSACTION_COUNT}}** |

---

## Top Merchants / Payees

| Rank | Payee | Total Spent | Visits | Category |
|------|-------|:-----------:|:------:|----------|
| 1 | {{TOP_PAYEE_1}} | {{TOP_PAYEE_1_AMOUNT}} | {{TOP_PAYEE_1_COUNT}} | {{TOP_PAYEE_1_CATEGORY}} |
| 2 | {{TOP_PAYEE_2}} | {{TOP_PAYEE_2_AMOUNT}} | {{TOP_PAYEE_2_COUNT}} | {{TOP_PAYEE_2_CATEGORY}} |
| 3 | {{TOP_PAYEE_3}} | {{TOP_PAYEE_3_AMOUNT}} | {{TOP_PAYEE_3_COUNT}} | {{TOP_PAYEE_3_CATEGORY}} |
| 4 | {{TOP_PAYEE_4}} | {{TOP_PAYEE_4_AMOUNT}} | {{TOP_PAYEE_4_COUNT}} | {{TOP_PAYEE_4_CATEGORY}} |
| 5 | {{TOP_PAYEE_5}} | {{TOP_PAYEE_5_AMOUNT}} | {{TOP_PAYEE_5_COUNT}} | {{TOP_PAYEE_5_CATEGORY}} |

---

## Uncategorised Transactions

{{UNCATEGORISED_COUNT}} uncategorised transactions totalling {{UNCATEGORISED_AMOUNT}}.

{{#if UNCATEGORISED_SAMPLE}}
Sample uncategorised payees:
{{UNCATEGORISED_SAMPLE}}
{{/if}}

> Run `./scripts/ps-list-transactions.sh --type uncategorised --start-date {{START_DATE}} --end-date {{END_DATE}}` to review and categorise these.

---

## Notes

- Amounts shown in {{CURRENCY_CODE}}. Transfers between accounts are excluded.
- Negative amounts represent spending; positive amounts represent refunds/credits.
- Data source: PocketSmith API v2 — `/users/{{USER_ID}}/transactions`
