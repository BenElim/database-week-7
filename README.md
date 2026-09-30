# PostgreSQL Lab: Audit Log, Category Tree, Flyway & Least Privilege

Solution to the PLP PostgreSQL lab, run against the `bootcamp` database.

## Files

- `answer.sql` - all SQL and shell commands for the five steps.
- `migrations/` - Flyway migrations `V1__core_tables.sql`, `V2__audit_log.sql`, `V3__categories.sql`.

## What I did

1. **Audit log** - an `audit_log` table plus a generic `audit()` trigger function. The `trg_audit` trigger on `students` stores each INSERT, UPDATE and DELETE with the old and new row as JSONB, who changed it, and when.
2. **Watching it work** - updated and deleted rows in `students`, then queried `audit_log` using `->>` to pull out the old and new `name`.
3. **Category tree** - a self-referencing `categories` table (`parent_id`) and a recursive CTE that walks from the root, tracking `depth` for indentation.
4. **Flyway** - split the schema into ordered, versioned migration files and applied them with `flyway migrate`; `flyway info` shows what has run.
5. **Least privilege** - `app_read` (SELECT only) and `app_write` (SELECT/INSERT/UPDATE/DELETE) roles, and an `api` login user that inherits `app_write`.

## Notes

- `to_jsonb(OLD)` is NULL on inserts and `to_jsonb(NEW)` is NULL on deletes, so the audit log shows which side is missing.
- The `GRANT ... ON ALL TABLES` statements only cover tables that exist at that moment. For future tables, add `ALTER DEFAULT PRIVILEGES`.
- The `strong-secret` password is a placeholder; do not commit real credentials.
