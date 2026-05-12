# PocketSmith Skill — Financial Safeguards

> Load this file when the user asks how the safeguard system works, wants to understand the audit log, or needs to override a safety check.

---

## Overview

All write operations (CREATE, UPDATE, DELETE) in this skill implement five layers of protection to prevent accidental or irreversible changes to financial data.

| Layer | What it protects against |
|-------|--------------------------|
| Dry-run default | Unintentional API calls during exploration |
| Delete confirmation | Accidental permanent deletion |
| Audit log | Untraceable changes |
| Read-only mode | Write operations in sensitive contexts |
| Input validation | Malformed data reaching the API |

---

## Layer 1 — Dry-Run Default (CREATE & UPDATE)

All CREATE and UPDATE scripts **do not call the API by default**. They print what *would* happen, including the full request body, so you can review before committing.

```sh
# This prints the curl command and payload — does NOT call the API:
./scripts/ps-create-transaction.sh \
  --transaction-account-id 555 --date 2025-05-10 --amount -45.00 --payee "Supermarket"

# This actually creates the transaction:
./scripts/ps-create-transaction.sh \
  --transaction-account-id 555 --date 2025-05-10 --amount -45.00 --payee "Supermarket" \
  --execute
```

Dry-run output format:
```
[DRY-RUN] Would execute:
  Method:   POST
  URL:      https://api.pocketsmith.com/v2/transaction-accounts/555/transactions
  Payload:  {"payee":"Supermarket","amount":-45.00,"date":"2025-05-10"}
Pass --execute to apply this change.
```

---

## Layer 2 — Explicit Confirmation (DELETE)

All DELETE scripts refuse to run without `--confirm`. This prevents accidental deletion from copy-paste errors or misread IDs.

```sh
# This exits with an error:
./scripts/ps-delete-transaction.sh --transaction-id 9876

# This deletes:
./scripts/ps-delete-transaction.sh --transaction-id 9876 --confirm
```

Error output (stderr):
```
ERROR: Destructive operation requires --confirm flag.
       Review the transaction ID before confirming:
         Transaction ID: 9876
       Re-run with --confirm to proceed.
```

---

## Layer 3 — Audit Log

Every write operation (including dry-runs) appends a line to `~/.pocketsmith-audit.log`.

### Audit log format

Each line is a tab-separated record:

```
<ISO8601_TIMESTAMP>\t<DRY_RUN|EXECUTED|DELETED>\t<OPERATION>\t<PARAMS_JSON>
```

### Example entries

```
2025-05-10T14:32:01Z	DRY_RUN	create_transaction	{"transaction_account_id":555,"payee":"Supermarket","amount":-45.00,"date":"2025-05-10"}
2025-05-10T14:32:45Z	EXECUTED	create_transaction	{"transaction_account_id":555,"payee":"Supermarket","amount":-45.00,"date":"2025-05-10","result_id":9877}
2025-05-10T15:00:00Z	DELETED	delete_transaction	{"transaction_id":9876,"confirmed":true}
```

### Viewing the audit log

```sh
# View recent entries
tail -20 ~/.pocketsmith-audit.log

# View all executions (not dry-runs)
grep 'EXECUTED\|DELETED' ~/.pocketsmith-audit.log

# View entries for a specific date
grep '^2025-05-10' ~/.pocketsmith-audit.log
```

### Log location

Default: `~/.pocketsmith-audit.log`

Override with environment variable:
```sh
export PS_AUDIT_LOG="/path/to/custom/audit.log"
```

---

## Layer 4 — Read-Only Mode

Set `PS_READ_ONLY=1` to unconditionally block all write scripts. Useful when:
- Sharing your shell with another user
- Running in a demo or review context
- CI pipelines that should only read data

```sh
export PS_READ_ONLY=1

# This will exit with error:
./scripts/ps-create-transaction.sh --transaction-account-id 555 --date 2025-05-10 --amount -45.00 --payee "Test"
# ERROR: PS_READ_ONLY=1 is set. Write operations are disabled.

# Read operations still work:
./scripts/ps-list-transactions.sh --start-date 2025-05-01 --end-date 2025-05-31
```

---

## Layer 5 — Input Validation

Scripts validate inputs before constructing API requests.

| Input | Validation rule | Error example |
|-------|----------------|---------------|
| `--amount` | Must be a numeric value (integer or decimal) | `ERROR: Amount must be numeric. Got: "forty-five"` |
| `--date`, `--start-date`, `--end-date` | Must match `YYYY-MM-DD` | `ERROR: Date must be YYYY-MM-DD format. Got: "10/05/2025"` |
| `--per-page` | Must be integer 1–100 | `ERROR: per-page must be 1-100. Got: "200"` |
| `--transaction-id` | Must be a non-zero integer | `ERROR: transaction-id must be a positive integer.` |
| `PS_API_KEY` | Must be set and non-empty | `ERROR: PS_API_KEY is not set. Export it or pass --api-key.` |

---

## Override Procedures

### Override dry-run for a one-off command
```sh
./scripts/ps-update-transaction.sh --transaction-id 9876 --note "Updated" --execute
```

### Temporarily disable read-only mode
```sh
PS_READ_ONLY=0 ./scripts/ps-create-transaction.sh ...
```

### Skip audit log for a session (not recommended)
```sh
export PS_AUDIT_LOG="/dev/null"
```

---

## Safeguard Behaviour Matrix

| Operation type | Dry-run default | Requires `--confirm` | Logged |
|---------------|:-:|:-:|:-:|
| GET / list (read) | n/a | No | No |
| CREATE | ✅ Yes | No | ✅ Yes |
| UPDATE | ✅ Yes | No | ✅ Yes |
| DELETE | ✅ Yes (prints what would be deleted) | ✅ Yes | ✅ Yes |
| apply-category-rules | ✅ Yes | No | ✅ Yes |

---

## Security Notes

- The API key (`PS_API_KEY`) is never written to the audit log.
- The audit log file is created with `600` permissions (owner read/write only) on first write.
- Scripts never store credentials to disk — they only read from the environment.
