# PocketSmith MCP Server — Tool Reference

> Load this file when an MCP-enabled client (Claude Desktop, Claude.ai, Claude Code) is available. MCP tools provide richer compound analysis than the shell scripts.

## Server URLs

| Access Level | URL | Tools |
|-------------|-----|-------|
| Full access | `https://mcp.pocketsmith.com/mcp` | 57 tools |
| Read-only | `https://mcp-readonly.pocketsmith.com/mcp` | 38 tools |

**Authentication:** OAuth 2.0 with PKCE — handled automatically by MCP-compatible clients. No API key setup required.

---

## Insights — Compound Analysis (Read-only)

These tools perform multi-step analysis and return rich structured summaries. Prefer these over raw API calls for user-facing analysis.

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| `financial_health_snapshot` | Net worth, spending pace, budget traffic lights, action items | `period` (optional) |
| `month_end_review` | Full period review: income/expenses, savings rate, budget variance, top payees | `year`, `month` |
| `spending_comparison` | Side-by-side comparison of two date ranges by category and payee | `period_1_start`, `period_1_end`, `period_2_start`, `period_2_end` |
| `find_recurring_expenses` | Detect subscriptions and recurring bills with annual cost totals | `months_back` (default 3) |
| `cash_flow_forecast` | Forward-looking account balance projections with danger-zone alerts | `months_ahead` |
| `net_worth_forecast` | Net worth trajectory: historical trend, forecast, milestone projections | `months_ahead` |
| `forecast_accuracy` | Compare actual vs forecast balances to evaluate budget reliability | `months_back` |

---

## Budgeting (Read + Write)

| Tool | Access | Description | Key Parameters |
|------|--------|-------------|----------------|
| `get_budget` | read | Budget analysis per category for the forecast period | `user_id` |
| `get_budget_summary` | read | Expense/income actuals vs budgeted for a date range | `user_id`, `start_date`, `end_date`, `roll_up` |
| `get_trend_analysis` | read | Spending trends over time by category | `user_id`, `period`, `num_periods`, `categories` |
| `delete_forecast_cache` | **write** | Force budget recalculation after bulk edits | `user_id` |

---

## Transactions (Read + Write)

| Tool | Access | Description | Key Parameters |
|------|--------|-------------|----------------|
| `list_transactions` | read | Search and filter transactions | `user_id`, `start_date`, `end_date`, `search`, `category_id`, `type`, `page`, `per_page` |
| `get_transaction` | read | Get a single transaction's full details | `id` |
| `create_transaction` | **write** | Add a new transaction | `transaction_account_id`, `payee`, `amount`, `date`, `note`, `category_id`, `labels` |
| `update_transaction` | **write** | Edit a transaction (payee, category, labels, notes, splits) | `id`, any updatable field |
| `delete_transaction` | **write** | Remove a transaction permanently | `id` |

---

## Accounts & Institutions (Read + Write)

| Tool | Access | Description | Key Parameters |
|------|--------|-------------|----------------|
| `list_accounts` | read | List all accounts by user or institution | `user_id` or `institution_id` |
| `get_account` | read | Get account details including balance and child accounts | `id` |
| `create_account` | **write** | Create a new account | `user_id`, `institution_id`, `title`, `currency_code`, `type` |
| `update_account` | **write** | Update an account's details | `id`, updatable fields |
| `delete_account` | **write** | Delete an account permanently | `id` |
| `update_account_display_order` | **write** | Reorder accounts in the UI | `user_id`, `[{id, display_position}]` |
| `list_institutions` | read | View financial institutions for a user | `user_id` |
| `get_institution` | read | Get institution details | `id` |
| `create_institution` | **write** | Create a new institution | `user_id`, `title`, `currency_code` |
| `update_institution` | **write** | Update an institution | `id`, `title`, `currency_code` |
| `delete_institution` | **write** | Delete an institution | `id` |
| `list_transaction_accounts` | read | List transaction accounts for a user | `user_id` |
| `get_transaction_account` | read | Get transaction account details | `id` |
| `update_transaction_account` | **write** | Update a transaction account | `id`, `starting_balance`, `starting_balance_date` |

---

## Categories & Rules (Read + Write)

| Tool | Access | Description | Key Parameters |
|------|--------|-------------|----------------|
| `list_categories` | read | View full category hierarchy | `user_id` |
| `get_category` | read | Get a single category | `id` |
| `create_category` | **write** | Create a new category | `user_id`, `title`, `colour`, `parent_id` |
| `update_category` | **write** | Update a category | `id`, updatable fields |
| `delete_category` | **write** | Delete a category | `id` |
| `list_category_rules` | read | View auto-categorisation rules | `user_id` |
| `create_category_rule` | **write** | Create an auto-categorisation rule | `category_id`, `payee_matches`, `apply_to_all`, `apply_to_uncategorised` |

---

## Budget Events (Read + Write)

| Tool | Access | Description | Key Parameters |
|------|--------|-------------|----------------|
| `list_events` | read | View budget forecast events | `user_id`, `start_date`, `end_date` |
| `get_event` | read | Get a single budget event | `id` |
| `create_event` | **write** | Create a recurring or one-off budget event | `scenario_id`, `amount`, `start_date`, `repeat_type`, `note`, `category_id` |
| `update_event` | **write** | Update a budget event | `id`, updatable fields |
| `delete_event` | **write** | Delete a budget event | `id` |

---

## Attachments (Read + Write)

| Tool | Access | Description | Key Parameters |
|------|--------|-------------|----------------|
| `list_attachments` | read | View receipt and document attachments | `user_id` or `transaction_id` |
| `get_attachment` | read | Get a single attachment | `id` |
| `create_attachment` | **write** | Upload an attachment | `user_id`, `title`, `file_name`, `file_data` (base64) |
| `update_attachment` | **write** | Update attachment metadata | `id`, `title` |
| `delete_attachment` | **write** | Delete an attachment | `id` |
| `assign_transaction_attachment` | **write** | Link an attachment to a transaction | `transaction_id`, `attachment_id` |
| `unassign_transaction_attachment` | **write** | Unlink an attachment from a transaction | `transaction_id`, `attachment_id` |

---

## Data Feeds (Read + Write)

| Tool | Access | Description | Key Parameters |
|------|--------|-------------|----------------|
| `get_data_feeds_connection_status` | read | Check bank feed sync status and provider details | `user_id` |
| `refresh_data_feeds_connection` | **write** | Trigger a sync for one or all bank feed connections | `user_id`, `connection_id` (optional) |

---

## Other (Read + Write)

| Tool | Access | Description | Key Parameters |
|------|--------|-------------|----------------|
| `get_current_user` | read | View user profile and settings | — |
| `update_user` | **write** | Update user profile and settings | `id`, updatable fields |
| `list_labels` | read | View all transaction labels | `user_id` |
| `list_saved_searches` | read | View saved transaction search filters | `user_id` |
| `list_currencies` | read | Currency reference data | — |
| `get_currency` | read | Get a single currency | `id` (ISO code, e.g. `AUD`) |
| `list_time_zones` | read | Time zone reference data | — |

---

## Tool Counts

| Category | Read | Write | Total |
|----------|------|-------|-------|
| Insights | 7 | 0 | 7 |
| Budgeting | 3 | 1 | 4 |
| Transactions | 2 | 3 | 5 |
| Accounts & Institutions | 8 | 6 | 14 |
| Categories & Rules | 3 | 4 | 7 |
| Budget Events | 2 | 3 | 5 |
| Attachments | 2 | 5 | 7 |
| Data Feeds | 1 | 1 | 2 |
| Other | 6 | 1 | 7 |
| **Total** | **34** | **24** | **57** |

> Note: read-only MCP endpoint exposes 38 tools (includes the 7 Insights tools and all read-access tools above).

---

## When to Use MCP vs Scripts

| Situation | Prefer |
|-----------|--------|
| Claude Desktop / Claude.ai client | MCP tools (richer, no auth setup) |
| Terminal / CI / automation | Shell scripts in `scripts/` |
| Compound analysis (health, forecast) | MCP `financial_health_snapshot`, `month_end_review` |
| Simple CRUD | Either — scripts are faster to test |
| Read-only safety required | MCP read-only endpoint OR `PS_READ_ONLY=1` with scripts |
