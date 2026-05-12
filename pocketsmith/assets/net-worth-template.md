# Net Worth Report: {{PERIOD_LABEL}}

**As at:** {{REPORT_DATE}}  
**Generated:** {{GENERATED_AT}}  
**Base Currency:** {{CURRENCY_CODE}}

---

## Net Worth Snapshot

| Metric | Amount |
|--------|--------|
| **Total Assets** | **{{TOTAL_ASSETS}}** |
| **Total Liabilities** | **{{TOTAL_LIABILITIES}}** |
| **Net Worth** | **{{NET_WORTH}}** |
| Change vs last month | {{NET_WORTH_CHANGE_MONTH}} ({{NET_WORTH_CHANGE_MONTH_PCT}}%) |
| Change vs last year | {{NET_WORTH_CHANGE_YEAR}} ({{NET_WORTH_CHANGE_YEAR_PCT}}%) |

---

## Assets

| Account | Type | Balance | Institution |
|---------|------|--------:|-------------|
| {{ASSET_1_NAME}} | {{ASSET_1_TYPE}} | {{ASSET_1_BALANCE}} | {{ASSET_1_INSTITUTION}} |
| {{ASSET_2_NAME}} | {{ASSET_2_TYPE}} | {{ASSET_2_BALANCE}} | {{ASSET_2_INSTITUTION}} |
| {{ASSET_3_NAME}} | {{ASSET_3_TYPE}} | {{ASSET_3_BALANCE}} | {{ASSET_3_INSTITUTION}} |
| {{ASSET_4_NAME}} | {{ASSET_4_TYPE}} | {{ASSET_4_BALANCE}} | {{ASSET_4_INSTITUTION}} |
| {{ASSET_5_NAME}} | {{ASSET_5_TYPE}} | {{ASSET_5_BALANCE}} | {{ASSET_5_INSTITUTION}} |
| | **Total Assets** | **{{TOTAL_ASSETS}}** | |

---

## Liabilities

| Account | Type | Balance | Institution |
|---------|------|--------:|-------------|
| {{LIABILITY_1_NAME}} | {{LIABILITY_1_TYPE}} | {{LIABILITY_1_BALANCE}} | {{LIABILITY_1_INSTITUTION}} |
| {{LIABILITY_2_NAME}} | {{LIABILITY_2_TYPE}} | {{LIABILITY_2_BALANCE}} | {{LIABILITY_2_INSTITUTION}} |
| {{LIABILITY_3_NAME}} | {{LIABILITY_3_TYPE}} | {{LIABILITY_3_BALANCE}} | {{LIABILITY_3_INSTITUTION}} |
| | **Total Liabilities** | **{{TOTAL_LIABILITIES}}** | |

---

## Net Worth Trend

| Period | Assets | Liabilities | Net Worth | Change |
|--------|-------:|:-----------:|----------:|:------:|
| {{TREND_1_PERIOD}} | {{TREND_1_ASSETS}} | {{TREND_1_LIABILITIES}} | {{TREND_1_NET_WORTH}} | — |
| {{TREND_2_PERIOD}} | {{TREND_2_ASSETS}} | {{TREND_2_LIABILITIES}} | {{TREND_2_NET_WORTH}} | {{TREND_2_CHANGE}} |
| {{TREND_3_PERIOD}} | {{TREND_3_ASSETS}} | {{TREND_3_LIABILITIES}} | {{TREND_3_NET_WORTH}} | {{TREND_3_CHANGE}} |
| {{TREND_4_PERIOD}} | {{TREND_4_ASSETS}} | {{TREND_4_LIABILITIES}} | {{TREND_4_NET_WORTH}} | {{TREND_4_CHANGE}} |
| {{TREND_5_PERIOD}} | {{TREND_5_ASSETS}} | {{TREND_5_LIABILITIES}} | {{TREND_5_NET_WORTH}} | {{TREND_5_CHANGE}} |
| {{TREND_6_PERIOD}} | {{TREND_6_ASSETS}} | {{TREND_6_LIABILITIES}} | {{TREND_6_NET_WORTH}} | {{TREND_6_CHANGE}} |

---

## Asset Allocation

| Asset Class | Value | % of Assets |
|-------------|------:|:-----------:|
| Cash & Savings | {{ALLOC_CASH}} | {{ALLOC_CASH_PCT}}% |
| Investments | {{ALLOC_INVESTMENTS}} | {{ALLOC_INVESTMENTS_PCT}}% |
| Property | {{ALLOC_PROPERTY}} | {{ALLOC_PROPERTY_PCT}}% |
| Other Assets | {{ALLOC_OTHER}} | {{ALLOC_OTHER_PCT}}% |
| **Total** | **{{TOTAL_ASSETS}}** | **100%** |

---

## Observations

- {{OBSERVATION_1}}
- {{OBSERVATION_2}}
- {{OBSERVATION_3}}

---

## Notes

- Balances shown in {{CURRENCY_CODE}} at exchange rates as of {{REPORT_DATE}}.
- Only accounts marked "included in net worth" are counted.
- Data source: PocketSmith API v2 — `/users/{{USER_ID}}/accounts`
