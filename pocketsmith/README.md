# PocketSmith Agent Skill

An [agentskills.io](https://agentskills.io)-compatible skill for interacting with [PocketSmith](https://www.pocketsmith.com) personal finance data via the PocketSmith API v2.

## What This Skill Does

- **Read** accounts, transactions, categories, budgets, events, labels, institutions, and attachments
- **Write** transactions, categories, and budget forecast events (with safeguards)
- **Report** on spending, income, net worth, cash flow, and budget vs actual
- **Analyse** financial health, month-end metrics, and recurring expenses

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| `curl` | HTTP requests to PocketSmith API |
| `jq` *(optional)* | Pretty-printed JSON output |
| PocketSmith account | Free or paid plan |
| PocketSmith API key | Settings → Developer → API Keys |

## Setup

```sh
# 1. Export your API key
export PS_API_KEY="your_api_key_here"

# 2. Fetch and export your user ID
./scripts/ps-get-user.sh
export PS_USER_ID="12345"

# 3. Validate connectivity
./scripts/ps-auth-check.sh

# 4. Make scripts executable (first time only)
chmod +x scripts/*.sh
```

## Safety Features

All write operations have layered safeguards:

| Safeguard | Behaviour |
|-----------|-----------|
| **Dry-run default** | CREATE/UPDATE scripts print intent but do NOT call the API without `--execute` |
| **Delete confirmation** | DELETE scripts refuse to run without `--confirm` |
| **Audit log** | All write attempts logged to `~/.pocketsmith-audit.log` |
| **Read-only mode** | `PS_READ_ONLY=1` blocks all write scripts |
| **Input validation** | Amounts must be numeric; dates must be `YYYY-MM-DD` |

## Directory Structure

```
pocketsmith/
├── SKILL.md                          # Skill definition (YAML + instructions)
├── README.md                         # This file
├── scripts/                          # One script per operation
│   ├── ps-auth-check.sh
│   ├── ps-get-user.sh
│   ├── ps-list-accounts.sh
│   ├── ps-get-account.sh
│   ├── ps-list-transactions.sh
│   ├── ps-get-transaction.sh
│   ├── ps-create-transaction.sh      # ⚠️ dry-run by default
│   ├── ps-update-transaction.sh      # ⚠️ dry-run by default
│   ├── ps-delete-transaction.sh      # 🔴 requires --confirm
│   ├── ps-list-categories.sh
│   ├── ps-get-category.sh
│   ├── ps-create-category.sh         # ⚠️ dry-run by default
│   ├── ps-update-category.sh         # ⚠️ dry-run by default
│   ├── ps-delete-category.sh         # 🔴 requires --confirm
│   ├── ps-list-category-rules.sh
│   ├── ps-apply-category-rules.sh    # ⚠️ dry-run by default
│   ├── ps-list-budget.sh
│   ├── ps-get-budget-summary.sh
│   ├── ps-list-events.sh
│   ├── ps-create-event.sh            # ⚠️ dry-run by default
│   ├── ps-update-event.sh            # ⚠️ dry-run by default
│   ├── ps-delete-event.sh            # 🔴 requires --confirm
│   ├── ps-list-institutions.sh
│   ├── ps-list-attachments.sh
│   ├── ps-list-labels.sh
│   ├── ps-list-saved-searches.sh
│   ├── ps-report-spending.sh
│   ├── ps-report-income.sh
│   ├── ps-report-net-worth.sh
│   ├── ps-report-cash-flow.sh
│   ├── ps-report-budget-vs-actual.sh
│   ├── ps-insights-health.sh
│   ├── ps-insights-month-review.sh
│   └── ps-insights-recurring.sh
├── references/
│   ├── api-endpoints.md              # Full API endpoint reference
│   ├── mcp-tools.md                  # PocketSmith MCP server tool list
│   ├── data-models.md                # JSON field reference for all objects
│   └── safeguards.md                 # Safeguard system documentation
└── assets/
    ├── spending-report-template.md
    ├── net-worth-template.md
    └── budget-report-template.md
```

## Quick Examples

```sh
# List all accounts
./scripts/ps-list-accounts.sh

# Search transactions
./scripts/ps-list-transactions.sh --start-date 2025-05-01 --end-date 2025-05-31 --search "coffee"

# Spending report (markdown output)
./scripts/ps-report-spending.sh --start-date 2025-05-01 --end-date 2025-05-31

# Budget vs actual
./scripts/ps-report-budget-vs-actual.sh --start-date 2025-05-01 --end-date 2025-05-31

# Financial health snapshot
./scripts/ps-insights-health.sh

# Create a transaction (dry-run)
./scripts/ps-create-transaction.sh \
  --transaction-account-id 555 \
  --date 2025-05-10 \
  --amount -45.00 \
  --payee "Supermarket"

# Create a transaction (execute)
./scripts/ps-create-transaction.sh \
  --transaction-account-id 555 \
  --date 2025-05-10 \
  --amount -45.00 \
  --payee "Supermarket" \
  --execute
```

## MCP Server (Alternative)

If using an MCP-enabled client (Claude Desktop, Claude.ai), connect directly:

- **Full access (57 tools):** `https://mcp.pocketsmith.com/mcp`
- **Read-only (38 tools):** `https://mcp-readonly.pocketsmith.com/mcp`

See [`references/mcp-tools.md`](references/mcp-tools.md) for the full tool list.

## License

MIT — see [`../LICENSE`](../LICENSE).
