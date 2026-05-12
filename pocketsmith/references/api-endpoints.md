# PocketSmith API v2 — Full Endpoint Reference

**Base URL:** `https://api.pocketsmith.com/v2`  
**Authentication:** `X-Developer-Key: <your_api_key>` request header  
**Content-Type:** `application/json` for request bodies

> Load this file when constructing a `curl` call not covered by a bundled script, or when debugging a non-200 API response.

---

## Users

| Method | Endpoint | Description | Key Params |
|--------|----------|-------------|------------|
| GET | `/me` | Get the authorised user | — |
| GET | `/users/{id}` | Get user by ID | `id` |
| PUT | `/users/{id}` | Update user | `id`; body: name, email, time_zone, currency |

---

## Institutions

| Method | Endpoint | Description | Key Params |
|--------|----------|-------------|------------|
| GET | `/institutions/{id}` | Get institution | `id` |
| PUT | `/institutions/{id}` | Update institution | `id`; body: title, currency_code |
| DELETE | `/institutions/{id}` | Delete institution | `id` |
| GET | `/users/{id}/institutions` | List institutions for user | `id` |
| POST | `/users/{id}/institutions` | Create institution | `id`; body: title, currency_code |

---

## Accounts

| Method | Endpoint | Description | Key Params |
|--------|----------|-------------|------------|
| GET | `/accounts/{id}` | Get account | `id` |
| PUT | `/accounts/{id}` | Update account | `id`; body: title, currency_code, type |
| DELETE | `/accounts/{id}` | Delete account | `id` |
| GET | `/users/{id}/accounts` | List accounts for user | `id` |
| PUT | `/users/{id}/accounts` | Update display order | `id`; body: `[{id, display_position}]` |
| POST | `/users/{id}/accounts` | Create account | `id`; body: institution_id, title, currency_code, type |
| GET | `/institutions/{id}/accounts` | List accounts in institution | `id` |

### Account types
`bank`, `credits`, `loans`, `mortgage`, `stocks`, `vehicle`, `property`, `insurance`, `pension`, `other_asset`, `other_liability`

---

## Transaction Accounts

| Method | Endpoint | Description | Key Params |
|--------|----------|-------------|------------|
| GET | `/transaction-accounts/{id}` | Get transaction account | `id` |
| PUT | `/transaction-accounts/{id}` | Update transaction account | `id`; body: starting_balance, starting_balance_date |
| GET | `/users/{id}/transaction-accounts` | List transaction accounts for user | `id` |

---

## Transactions

| Method | Endpoint | Description | Key Params |
|--------|----------|-------------|------------|
| GET | `/transactions/{id}` | Get a transaction | `id` |
| PUT | `/transactions/{id}` | Update a transaction | `id`; body (any): payee, amount, date, note, category_id, labels, needs_review |
| DELETE | `/transactions/{id}` | Delete a transaction | `id` |
| GET | `/users/{id}/transactions` | List transactions for user | `id`; query: start_date, end_date, updated_since, search, category_id, type, needs_review, page, per_page |
| GET | `/accounts/{id}/transactions` | List transactions in account | `id`; query: same as above |
| GET | `/categories/{id}/transactions` | List transactions in category | `id`; query: start_date, end_date, page, per_page |
| GET | `/transaction-accounts/{id}/transactions` | List transactions in txn account | `id`; query: start_date, end_date, page, per_page |
| POST | `/transaction-accounts/{id}/transactions` | Create a transaction | `id`; body: payee, amount, date, note, category_id, labels, needs_review |

### Transaction query params

| Param | Type | Description |
|-------|------|-------------|
| `start_date` | YYYY-MM-DD | Filter from date (inclusive) |
| `end_date` | YYYY-MM-DD | Filter to date (inclusive) |
| `updated_since` | ISO 8601 | Transactions updated after this time |
| `search` | string | Keyword search across payee, notes |
| `category_id` | integer | Filter by category |
| `type` | `uncategorised\|debit\|credit` | Filter by type |
| `needs_review` | boolean | Filter by review flag |
| `page` | integer | Page number (default: 1) |
| `per_page` | integer | Results per page (default: 30, max: 100) |

---

## Categories

| Method | Endpoint | Description | Key Params |
|--------|----------|-------------|------------|
| GET | `/categories/{id}` | Get category | `id` |
| PUT | `/categories/{id}` | Update category | `id`; body: title, colour, parent_id, is_transfer, refund_behaviour |
| DELETE | `/categories/{id}` | Delete category | `id` |
| GET | `/users/{id}/categories` | List categories for user | `id` |
| POST | `/users/{id}/categories` | Create category | `id`; body: title, colour, parent_id, is_transfer, refund_behaviour |

### Refund behaviours
`debits_are_deductions`, `credits_are_income`, `both`

---

## Category Rules

| Method | Endpoint | Description | Key Params |
|--------|----------|-------------|------------|
| GET | `/users/{id}/category-rules` | List category rules for user | `id` |
| POST | `/categories/{id}/category-rules` | Create category rule | `id`; body: payee_matches, apply_to_all, apply_to_uncategorised |

---

## Budgeting

| Method | Endpoint | Description | Key Params |
|--------|----------|-------------|------------|
| GET | `/users/{id}/budget` | List budget for user | `id` |
| GET | `/users/{id}/budget-summary` | Get budget summary | `id`; query: start_date, end_date, roll_up |
| GET | `/users/{id}/trend-analysis` | Get trend analysis | `id`; query: period, num_periods, categories, scenario_id |
| DELETE | `/users/{id}/forecast-cache` | Delete forecast cache | `id` |

### Budget summary params

| Param | Type | Description |
|-------|------|-------------|
| `start_date` | YYYY-MM-DD | Period start |
| `end_date` | YYYY-MM-DD | Period end |
| `roll_up` | boolean | Roll sub-categories into parent |

### Trend analysis params

| Param | Type | Description |
|-------|------|-------------|
| `period` | YYYY-MM | Starting period (month) |
| `num_periods` | integer | Number of months to include |
| `categories` | comma-separated IDs | Filter to specific categories |
| `scenario_id` | integer | Scenario to include in forecast |

---

## Events (Budget Forecast Events)

| Method | Endpoint | Description | Key Params |
|--------|----------|-------------|------------|
| GET | `/events/{id}` | Get event | `id` |
| PUT | `/events/{id}` | Update event | `id`; body: amount, start_date, end_date, repeat_type, repeat_interval, note, category_id |
| DELETE | `/events/{id}` | Delete event | `id` |
| GET | `/users/{id}/events` | List events for user | `id`; query: start_date, end_date |
| GET | `/scenarios/{id}/events` | List events in scenario | `id`; query: start_date, end_date |
| POST | `/scenarios/{id}/events` | Create event in scenario | `id`; body: amount, start_date, end_date, repeat_type, repeat_interval, note, category_id |

### Repeat types
`once`, `daily`, `weekly`, `fortnightly`, `monthly`, `yearly`, `every_N_days`, `every_N_weeks`, `every_N_months`

---

## Attachments

| Method | Endpoint | Description | Key Params |
|--------|----------|-------------|------------|
| GET | `/attachments/{id}` | Get attachment | `id` |
| PUT | `/attachments/{id}` | Update attachment | `id`; body: title |
| DELETE | `/attachments/{id}` | Delete attachment | `id` |
| GET | `/users/{id}/attachments` | List attachments for user | `id` |
| POST | `/users/{id}/attachments` | Create attachment | `id`; body: title, file_name, file_data (base64) |
| GET | `/transactions/{id}/attachments` | List attachments for transaction | `id` |
| POST | `/transactions/{id}/attachments` | Assign attachment to transaction | `id`; body: attachment_id |
| DELETE | `/transactions/{txn_id}/attachments/{att_id}` | Unassign attachment | `txn_id`, `att_id` |

---

## Labels

| Method | Endpoint | Description | Key Params |
|--------|----------|-------------|------------|
| GET | `/users/{id}/labels` | List labels for user | `id` |

---

## Saved Searches

| Method | Endpoint | Description | Key Params |
|--------|----------|-------------|------------|
| GET | `/users/{id}/saved-searches` | List saved searches for user | `id` |

---

## Currencies

| Method | Endpoint | Description | Key Params |
|--------|----------|-------------|------------|
| GET | `/currencies` | List all currencies | — |
| GET | `/currencies/{id}` | Get currency by ISO code | `id` (e.g. `USD`, `AUD`) |

---

## Time Zones

| Method | Endpoint | Description | Key Params |
|--------|----------|-------------|------------|
| GET | `/time-zones` | List all time zones | — |

---

## Common curl Pattern

```sh
curl -s \
  -H "X-Developer-Key: $PS_API_KEY" \
  -H "Content-Type: application/json" \
  "https://api.pocketsmith.com/v2/me"
```

## HTTP Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | OK | Success |
| 201 | Created | Resource created |
| 204 | No Content | Success (DELETE) |
| 400 | Bad Request | Check request body |
| 401 | Unauthorized | Check `PS_API_KEY` |
| 403 | Forbidden | Key lacks scope |
| 404 | Not Found | Check IDs |
| 422 | Unprocessable Entity | Validation error — check field formats |
| 429 | Too Many Requests | Rate limited — back off and retry |
| 500 | Server Error | PocketSmith-side — retry later |
