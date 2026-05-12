---
name: pocketsmith
description: >
  Queries and manages PocketSmith personal finance data via the PocketSmith API v2.
  Use when the user asks about their finances, bank accounts, transactions, budgets,
  categories, spending trends, budget events, forecasts, or net worth in PocketSmith.
  Provides read operations (list/get accounts, transactions, budgets, categories,
  events, labels, institutions) and write operations (create/update/delete
  transactions, events, categories). Use when the user mentions "pocketsmith",
  wants to review "spending", check "budget" status, manage "transactions",
  analyse "net worth", run a "financial report", view "accounts", or manage
  "financial forecasts". All write operations include dry-run and audit logging.
license: MIT
compatibility: >
  Requires curl and internet access. Optionally requires jq for pretty-printed output.
  Set PS_API_KEY env var (mandatory). Set PS_USER_ID env var (recommended — fetch once
  with ps-get-user.sh). Set PS_READ_ONLY=1 to prevent all write operations.
  Tested on macOS (zsh) and Linux (sh/bash). POSIX sh throughout.
metadata:
  author: Keith Patton
  author_id: github.com/kaipee
  version: "1.0"
  api_version: v2
  api_base: https://api.pocketsmith.com/v2
  mcp_full: https://mcp.pocketsmith.com/mcp
  mcp_readonly: https://mcp-readonly.pocketsmith.com/mcp
---

# PocketSmith Skill

Interact with PocketSmith personal finance data via API v2. All scripts live in `scripts/`.

---

## Authentication

1. Log in to PocketSmith → **Settings → Developer → API Keys → New API Key**.
2. Export in your shell (add to `~/.zshrc` or `~/.bashrc`):
   ```sh
   export PS_API_KEY="your_api_key_here"
   ```
3. Fetch your user ID once and also export it:
   ```sh
   ./scripts/ps-get-user.sh          # note the "id" field
   export PS_USER_ID="12345"
   ```
4. Validate everything works:
   ```sh
   ./scripts/ps-auth-check.sh
   ```

> For MCP setup (Claude Desktop / Claude.ai), see [`references/mcp-tools.md`](references/mcp-tools.md).

---

## Data Model

**Institution → Account → Transaction Account / Scenario**

- **Institution**: a bank or brokerage (e.g. "ANZ Bank").
- **Account**: a logical container (e.g. "Everyday Cheque"). Groups one or more transaction accounts.
- **Transaction Account**: holds the actual transaction records. Use its ID to create transactions.
- **Scenario**: holds budget forecast *events* that drive the forecasting engine. Linked to an Account.
- **Categories**: hierarchical (parent/child). Shared across all accounts.
- **Labels**: free-form tags on transactions for flexible grouping.

> Load [`references/data-models.md`](references/data-models.md) when the user asks about account structure or scenario/event relationships.

---

## Quick Start

```sh
# 1. Check auth
./scripts/ps-auth-check.sh

# 2. List accounts
./scripts/ps-list-accounts.sh

# 3. List this month's transactions
./scripts/ps-list-transactions.sh --start-date 2025-05-01 --end-date 2025-05-31

# 4. Check budget status
./scripts/ps-list-budget.sh

# 5. Run a spending report
./scripts/ps-report-spending.sh --start-date 2025-05-01 --end-date 2025-05-31
```

---

## Core Operations

### Accounts & Institutions

| Script | Purpose | Key flags |
|--------|---------|-----------|
| [`ps-list-accounts.sh`](scripts/ps-list-accounts.sh) | All accounts for user | `--user-id` |
| [`ps-get-account.sh`](scripts/ps-get-account.sh) | Single account details | `--account-id` |
| [`ps-list-institutions.sh`](scripts/ps-list-institutions.sh) | All institutions | `--user-id` |

### Transactions

| Script | Purpose | Key flags |
|--------|---------|-----------|
| [`ps-list-transactions.sh`](scripts/ps-list-transactions.sh) | List/search transactions | `--start-date`, `--end-date`, `--search`, `--category-id`, `--type`, `--page`, `--per-page` |
| [`ps-get-transaction.sh`](scripts/ps-get-transaction.sh) | Single transaction | `--transaction-id` |
| [`ps-create-transaction.sh`](scripts/ps-create-transaction.sh) | Create transaction ⚠️ | `--transaction-account-id`, `--date`, `--amount`, `--payee`, `--execute` |
| [`ps-update-transaction.sh`](scripts/ps-update-transaction.sh) | Update transaction ⚠️ | `--transaction-id`, `--payee`, `--category-id`, `--note`, `--labels`, `--execute` |
| [`ps-delete-transaction.sh`](scripts/ps-delete-transaction.sh) | Delete transaction 🔴 | `--transaction-id`, `--confirm` |
| [`ps-list-attachments.sh`](scripts/ps-list-attachments.sh) | Attachments on transaction | `--transaction-id` |

### Categories & Rules

| Script | Purpose | Key flags |
|--------|---------|-----------|
| [`ps-list-categories.sh`](scripts/ps-list-categories.sh) | Full category hierarchy | `--user-id` |
| [`ps-get-category.sh`](scripts/ps-get-category.sh) | Single category | `--category-id` |
| [`ps-create-category.sh`](scripts/ps-create-category.sh) | Create category ⚠️ | `--title`, `--colour`, `--parent-id`, `--execute` |
| [`ps-update-category.sh`](scripts/ps-update-category.sh) | Update category ⚠️ | `--category-id`, `--title`, `--execute` |
| [`ps-delete-category.sh`](scripts/ps-delete-category.sh) | Delete category 🔴 | `--category-id`, `--confirm` |
| [`ps-list-category-rules.sh`](scripts/ps-list-category-rules.sh) | Auto-categorisation rules | `--user-id` |
| [`ps-apply-category-rules.sh`](scripts/ps-apply-category-rules.sh) | Apply rules to transactions ⚠️ | `--category-id`, `--execute` |

### Budget & Forecasting

| Script | Purpose | Key flags |
|--------|---------|-----------|
| [`ps-list-budget.sh`](scripts/ps-list-budget.sh) | Budget analysis per category | `--user-id` |
| [`ps-get-budget-summary.sh`](scripts/ps-get-budget-summary.sh) | Actuals vs budgeted | `--start-date`, `--end-date` |
| [`ps-list-events.sh`](scripts/ps-list-events.sh) | Budget forecast events | `--start-date`, `--end-date` |
| [`ps-create-event.sh`](scripts/ps-create-event.sh) | Create forecast event ⚠️ | `--scenario-id`, `--start-date`, `--amount`, `--execute` |
| [`ps-update-event.sh`](scripts/ps-update-event.sh) | Update forecast event ⚠️ | `--event-id`, `--execute` |
| [`ps-delete-event.sh`](scripts/ps-delete-event.sh) | Delete forecast event 🔴 | `--event-id`, `--confirm` |

### Other

| Script | Purpose | Key flags |
|--------|---------|-----------|
| [`ps-list-labels.sh`](scripts/ps-list-labels.sh) | All transaction labels | `--user-id` |
| [`ps-list-saved-searches.sh`](scripts/ps-list-saved-searches.sh) | Saved search filters | `--user-id` |

> ⚠️ = dry-run by default (add `--execute` to apply)  
> 🔴 = requires `--confirm` flag; irreversible

---

## Reports

All report and insight scripts accept `--start-date` and `--end-date` (YYYY-MM-DD) and `--format json|markdown` (default: `markdown`).

| Script | What it produces |
|--------|----------------|
| [`ps-report-spending.sh`](scripts/ps-report-spending.sh) | Spending by category with percentages and top merchants |
| [`ps-report-income.sh`](scripts/ps-report-income.sh) | Income by category and period |
| [`ps-report-net-worth.sh`](scripts/ps-report-net-worth.sh) | Assets, liabilities, and net worth over time |
| [`ps-report-cash-flow.sh`](scripts/ps-report-cash-flow.sh) | Income vs expenses by period |
| [`ps-report-budget-vs-actual.sh`](scripts/ps-report-budget-vs-actual.sh) | Budget vs actual with variance |
| [`ps-insights-health.sh`](scripts/ps-insights-health.sh) | Composite financial health score |
| [`ps-insights-month-review.sh`](scripts/ps-insights-month-review.sh) | Month-end summary of key metrics |
| [`ps-insights-recurring.sh`](scripts/ps-insights-recurring.sh) | Recurring charges identified by pattern |

Templates for report output: [`assets/spending-report-template.md`](assets/spending-report-template.md), [`assets/net-worth-template.md`](assets/net-worth-template.md), [`assets/budget-report-template.md`](assets/budget-report-template.md).

---

## Safeguards

All write operations implement four layers of protection:

1. **Dry-run by default** — CREATE/UPDATE scripts print the action and payload but do not call the API unless `--execute` is passed.
2. **Explicit confirmation** — DELETE scripts refuse to run without `--confirm`.
3. **Audit log** — every write (even dry-runs) appends to `~/.pocketsmith-audit.log`.
4. **Read-only mode** — set `PS_READ_ONLY=1` to block all write scripts unconditionally.
5. **Input validation** — amounts must be numeric; dates must match `YYYY-MM-DD`.

> Load [`references/safeguards.md`](references/safeguards.md) for full detail on audit log format and override procedures.

---

## Common Workflows

### Review current month budget
```sh
./scripts/ps-list-budget.sh
./scripts/ps-report-budget-vs-actual.sh --start-date 2025-05-01 --end-date 2025-05-31
```

### Find and categorise uncategorised transactions
```sh
./scripts/ps-list-transactions.sh --type uncategorised --start-date 2025-05-01 --end-date 2025-05-31
./scripts/ps-update-transaction.sh --transaction-id 9876 --category-id 42 --execute
```

### Add a manual transaction
```sh
# Dry-run first (default):
./scripts/ps-create-transaction.sh \
  --transaction-account-id 555 --date 2025-05-10 --amount -45.00 --payee "Supermarket"
# Apply:
./scripts/ps-create-transaction.sh \
  --transaction-account-id 555 --date 2025-05-10 --amount -45.00 --payee "Supermarket" --execute
```

### Create a budget forecast event
```sh
./scripts/ps-create-event.sh \
  --scenario-id 77 --start-date 2025-06-01 --amount -120.00 \
  --repeat-type monthly --note "Gym membership" --execute
```

### Monthly spending analysis
```sh
./scripts/ps-report-spending.sh --start-date 2025-05-01 --end-date 2025-05-31
./scripts/ps-insights-month-review.sh --start-date 2025-05-01 --end-date 2025-05-31
```

---

## Gotchas

- **User ID ≠ API key**: fetch it once with `ps-get-user.sh`; set `PS_USER_ID`.
- **Transaction accounts ≠ accounts**: transactions live in *transaction accounts*. Use `ps-list-accounts.sh` to find the account, then inspect the `primary_transaction_account.id` field.
- **Budget events live in scenarios**: to create an event you need a *scenario ID*, not an account ID.
- **After bulk edits**: run `ps-get-budget-summary.sh` after bulk transaction changes — the forecast may be stale.
- **Dates**: always `YYYY-MM-DD`. The API rejects other formats silently.
- **Negative amounts = expenses**: PocketSmith convention — expenses are negative, income is positive.
- **Pagination**: `ps-list-transactions.sh` defaults to 100 per page. Use `--page 2` for subsequent pages.

---

## Error Handling

> Load [`references/api-endpoints.md`](references/api-endpoints.md) to construct custom `curl` calls not covered by bundled scripts.

Common errors: `401 Unauthorized` = bad/missing API key; `403 Forbidden` = insufficient scope; `404 Not Found` = wrong ID; `422 Unprocessable` = validation error (check field formats); `429 Too Many Requests` = back off and retry.

---

## MCP Alternative

If running inside Claude Desktop, Claude.ai, or another MCP-enabled client, prefer the PocketSmith MCP server for richer compound analysis:

- **Full access (57 tools):** `https://mcp.pocketsmith.com/mcp`
- **Read-only (38 tools):** `https://mcp-readonly.pocketsmith.com/mcp`

> Load [`references/mcp-tools.md`](references/mcp-tools.md) for the full tool list and usage notes.

---

## When to Load References

| Situation | Load |
|-----------|------|
| API returns non-200 error | [`references/api-endpoints.md`](references/api-endpoints.md) |
| Need to construct a raw curl call | [`references/api-endpoints.md`](references/api-endpoints.md) |
| User asks about account/scenario structure | [`references/data-models.md`](references/data-models.md) |
| MCP client is available | [`references/mcp-tools.md`](references/mcp-tools.md) |
| User needs API key setup help | [`references/api-endpoints.md`](references/api-endpoints.md) |
| User asks how safeguards/audit log works | [`references/safeguards.md`](references/safeguards.md) |
| Formatting report output | [`assets/spending-report-template.md`](assets/spending-report-template.md) |
