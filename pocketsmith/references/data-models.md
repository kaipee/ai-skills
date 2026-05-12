# PocketSmith Data Models Reference

> Load this file when the user asks about account structure, data relationships, or when you need field-level detail for constructing API payloads.

---

## Object Hierarchy

```
Institution
  └── Account (logical container)
        ├── Transaction Account  ← holds transaction records
        └── Scenario             ← holds budget forecast events
```

- **User** owns all of the above.
- **Categories** are user-scoped and hierarchical — shared across all accounts.
- **Labels** are free-form tags attached to individual transactions.

---

## User

```json
{
  "id": 12345,
  "login": "john.doe",
  "name": "John Doe",
  "email": "john@example.com",
  "avatar_url": "https://...",
  "beta_user": false,
  "time_zone": "Australia/Melbourne",
  "week_start_day": 0,
  "is_reviewing_transactions": false,
  "base_currency_code": "AUD",
  "always_show_base_currency": false,
  "using_multiple_currencies": false,
  "available_accounts": 5,
  "available_scenarios": 3,
  "created_at": "2020-01-01T00:00:00Z",
  "updated_at": "2025-05-01T00:00:00Z"
}
```

| Field | Type | Notes |
|-------|------|-------|
| `id` | integer | Use as `{user_id}` in all `/users/{id}/...` endpoints |
| `base_currency_code` | string | ISO 4217 (e.g. `AUD`, `USD`) |
| `time_zone` | string | TZ database name |
| `week_start_day` | integer | 0=Sunday, 1=Monday |

---

## Institution

```json
{
  "id": 101,
  "title": "ANZ Bank",
  "currency_code": "AUD",
  "created_at": "2021-03-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
```

---

## Account

```json
{
  "id": 201,
  "title": "Everyday Cheque",
  "currency_code": "AUD",
  "type": "bank",
  "subtype": "checking",
  "is_net_worth": true,
  "primary_transaction_account": { "id": 301, ... },
  "primary_scenario": { "id": 401, ... },
  "transaction_accounts": [ ... ],
  "scenarios": [ ... ],
  "institution": { "id": 101, "title": "ANZ Bank" },
  "current_balance": 2450.00,
  "current_balance_date": "2025-05-10",
  "current_balance_in_base_currency": 2450.00,
  "current_balance_exchange_rate": 1.0,
  "safe_balance": 2100.00,
  "safe_balance_in_base_currency": 2100.00,
  "created_at": "2021-03-01T00:00:00Z",
  "updated_at": "2025-05-10T00:00:00Z"
}
```

| Field | Type | Notes |
|-------|------|-------|
| `id` | integer | Account container ID |
| `type` | string | See account types below |
| `primary_transaction_account.id` | integer | Use this ID to create transactions |
| `primary_scenario.id` | integer | Use this ID to create budget events |
| `current_balance` | float | Live balance in account currency |
| `safe_balance` | float | Balance minus scheduled future debits |

### Account types
`bank`, `credits`, `loans`, `mortgage`, `stocks`, `vehicle`, `property`, `insurance`, `pension`, `other_asset`, `other_liability`

---

## Transaction Account

```json
{
  "id": 301,
  "name": "Everyday Cheque",
  "number": "***1234",
  "current_balance": 2450.00,
  "current_balance_date": "2025-05-10",
  "starting_balance": 0.00,
  "starting_balance_date": "2021-03-01",
  "created_at": "2021-03-01T00:00:00Z",
  "updated_at": "2025-05-10T00:00:00Z",
  "institution": { "id": 101, "title": "ANZ Bank" },
  "currency_code": "AUD",
  "type": "bank"
}
```

> **Important:** To create a transaction, POST to `/transaction-accounts/{id}/transactions` using the Transaction Account `id`, **not** the Account `id`.

---

## Transaction

```json
{
  "id": 9876,
  "payee": "Woolworths",
  "original_payee": "WOOLWORTHS 1234",
  "date": "2025-05-10",
  "upload_source": "statement_import",
  "category": { "id": 42, "title": "Groceries" },
  "closing_balance": 2405.00,
  "cheque_number": null,
  "memo": null,
  "amount": -45.00,
  "amount_in_base_currency": -45.00,
  "type": "debit",
  "is_transfer": false,
  "needs_review": false,
  "note": "Weekly shop",
  "labels": ["household", "groceries"],
  "transaction_account": { "id": 301 },
  "created_at": "2025-05-10T08:30:00Z",
  "updated_at": "2025-05-10T08:30:00Z"
}
```

| Field | Type | Notes |
|-------|------|-------|
| `id` | integer | Transaction ID |
| `amount` | float | Negative = expense/debit, positive = income/credit |
| `date` | YYYY-MM-DD | Transaction date |
| `payee` | string | User-edited payee name |
| `original_payee` | string | Raw payee from bank feed |
| `category` | object | Nullable if uncategorised |
| `labels` | array of strings | Free-form tags |
| `needs_review` | boolean | Flag for manual review |
| `type` | string | `debit`, `credit` |
| `is_transfer` | boolean | True if a transfer between accounts |

### Updatable fields (PUT `/transactions/{id}`)
`payee`, `date`, `amount`, `note`, `memo`, `category_id`, `labels`, `needs_review`, `is_transfer`, `cheque_number`

---

## Category

```json
{
  "id": 42,
  "title": "Groceries",
  "colour": "#4CAF50",
  "parent_id": 10,
  "is_transfer": false,
  "is_bill": false,
  "refund_behaviour": null,
  "children": [
    { "id": 43, "title": "Supermarkets", ... }
  ],
  "created_at": "2020-06-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

| Field | Type | Notes |
|-------|------|-------|
| `parent_id` | integer or null | Null = top-level category |
| `colour` | string | Hex colour code |
| `refund_behaviour` | string or null | `debits_are_deductions`, `credits_are_income`, `both`, or null |
| `children` | array | Sub-categories (only in list response) |

---

## Budget Event

```json
{
  "id": 5001,
  "scenario": { "id": 401 },
  "category": { "id": 42, "title": "Groceries" },
  "amount": -200.00,
  "amount_in_base_currency": -200.00,
  "currency_code": "AUD",
  "date": "2025-06-01",
  "repeat_type": "monthly",
  "repeat_interval": 1,
  "note": "Monthly grocery budget",
  "infinite_series": true,
  "end_date": null,
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
```

| Field | Type | Notes |
|-------|------|-------|
| `scenario.id` | integer | The scenario this event belongs to |
| `amount` | float | Negative = expense event, positive = income event |
| `repeat_type` | string | See repeat types below |
| `repeat_interval` | integer | Every N units of repeat_type (e.g. every 2 weeks) |
| `infinite_series` | boolean | True if no end date |

### Repeat types
`once`, `daily`, `weekly`, `fortnightly`, `monthly`, `yearly`, `every_N_days`, `every_N_weeks`, `every_N_months`

---

## Scenario

```json
{
  "id": 401,
  "title": "Primary",
  "description": null,
  "interest_rate": 0.0,
  "interest_rate_repeat_id": 4,
  "type": "savings",
  "minimum_value": null,
  "maximum_value": null,
  "account": { "id": 201 },
  "created_at": "2021-03-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
```

> **To create a budget event:** POST to `/scenarios/{scenario_id}/events`. Get the `scenario.id` from the Account object's `primary_scenario.id` field.

---

## Budget Summary Item

```json
{
  "category": { "id": 42, "title": "Groceries" },
  "start_date": "2025-05-01",
  "end_date": "2025-05-31",
  "budget_amount": -200.00,
  "actual_amount": -187.50,
  "refund_amount": 0.00,
  "currency_code": "AUD",
  "type": "expense",
  "is_current": true,
  "refund_behaviour": null
}
```

---

## Label

```json
{
  "id": 1,
  "title": "household"
}
```

---

## Attachment

```json
{
  "id": 7001,
  "title": "Receipt - Woolworths",
  "file_name": "receipt.jpg",
  "file_type": "image/jpeg",
  "file_size": 204800,
  "file_url": "https://...",
  "created_at": "2025-05-10T09:00:00Z",
  "updated_at": "2025-05-10T09:00:00Z"
}
```

---

## Key Relationships Summary

| To do this… | You need… |
|-------------|-----------|
| Create a transaction | `transaction_account_id` (from `account.primary_transaction_account.id`) |
| Create a budget event | `scenario_id` (from `account.primary_scenario.id`) |
| Filter transactions by category | `category_id` |
| Update a transaction | `transaction_id` |
| Delete an event | `event_id` |
| Get budget vs actual | `user_id` + `start_date` + `end_date` |
