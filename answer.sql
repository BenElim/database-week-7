-- =====================================================================
-- Lab: Audit Log, Category Tree, Flyway Migrations, Least Privilege
-- Database: bootcamp
-- Lines starting with "-- $" are shell commands; everything else is SQL.
-- =====================================================================


-- =====================================================================
-- STEP 1: Build a reusable audit log
-- =====================================================================
CREATE TABLE audit_log (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tbl TEXT,
  op TEXT,
  old_row JSONB,
  new_row JSONB,
  changed_by TEXT DEFAULT current_user,
  at TIMESTAMPTZ DEFAULT now()
);

CREATE OR REPLACE FUNCTION audit() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_log(tbl, op, old_row, new_row)
  VALUES (
    TG_TABLE_NAME,
    TG_OP,
    to_jsonb(OLD),   -- NULL on INSERT
    to_jsonb(NEW)    -- NULL on DELETE
  );
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit
AFTER INSERT OR UPDATE OR DELETE
ON students
FOR EACH ROW
EXECUTE FUNCTION audit();


-- =====================================================================
-- STEP 2: Watch the audit log work
-- =====================================================================
UPDATE students SET name = 'Kofi M.' WHERE id = 1;
DELETE FROM students WHERE id = 3;

SELECT
  tbl,
  op,
  old_row->>'name' AS was,
  new_row->>'name' AS now,
  at
FROM audit_log
ORDER BY at DESC, id DESC;   -- id breaks ties inside one transaction


-- =====================================================================
-- STEP 3: Model a category tree
-- =====================================================================
CREATE TABLE categories (
  id SERIAL PRIMARY KEY,
  name TEXT,
  parent_id INT REFERENCES categories(id)
);

INSERT INTO categories (name, parent_id) VALUES
  ('Electronics', NULL),
  ('Computers', 1),
  ('Laptops', 2),
  ('Phones', 1);

WITH RECURSIVE tree AS (
  SELECT id, name, parent_id, 0 AS depth
  FROM categories
  WHERE parent_id IS NULL

  UNION ALL

  SELECT c.id, c.name, c.parent_id, t.depth + 1
  FROM categories c
  JOIN tree t ON c.parent_id = t.id
)
SELECT repeat('  ', depth) || name AS tree
FROM tree
ORDER BY depth, name;


-- =====================================================================
-- STEP 4: Versioned migrations with Flyway
-- =====================================================================
-- Migration files (see the migrations/ folder):
--   V1__core_tables.sql
--   V2__audit_log.sql
--   V3__categories.sql
--
-- $ flyway -url=jdbc:postgresql://localhost/bootcamp -user=postgres migrate
-- $ flyway info
--
-- Flyway records each applied file in the flyway_schema_history table.
-- If the database already has these tables, run first:
-- $ flyway -url=jdbc:postgresql://localhost/bootcamp -user=postgres -baselineVersion=0 baseline
-- (or start on a fresh database).


-- =====================================================================
-- STEP 5: Least-privilege security
-- =====================================================================
CREATE ROLE app_read;
CREATE ROLE app_write;

GRANT CONNECT ON DATABASE bootcamp TO app_read, app_write;
GRANT USAGE ON SCHEMA public TO app_read, app_write;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_read;
GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public TO app_write;

-- Needed so INSERTs into SERIAL tables (e.g. categories) work:
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO app_write;

CREATE USER api
LOGIN PASSWORD 'strong-secret'   -- placeholder: use a real secret, never commit it
IN ROLE app_write;

-- Verify:
-- $ psql -U api -h localhost -d bootcamp -c "SELECT count(*) FROM students;"
