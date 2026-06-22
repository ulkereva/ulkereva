-- ============================================================
-- Data Validation Queries for QA
-- Author: Ülkər Əliyeva
-- Purpose: back-end checks to validate data integrity during testing.
-- Table/column names are illustrative — adapt to the system under test.
-- ============================================================


-- 1. Row count sanity check
--    Confirm a table has the expected number of records.
SELECT COUNT(*) AS total_users
FROM users;


-- 2. Duplicate detection
--    A unique constraint (one account per email) should hold — this returns violations.
SELECT email, COUNT(*) AS occurrences
FROM users
GROUP BY email
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- 3. NULL / completeness check
--    Required fields must not be NULL or empty.
SELECT id, email
FROM users
WHERE email IS NULL
   OR TRIM(email) = '';


-- 4. Referential integrity — orphaned rows
--    Orders that reference a user that no longer exists (broken foreign key).
SELECT o.id AS order_id, o.user_id
FROM orders o
LEFT JOIN users u ON u.id = o.user_id
WHERE u.id IS NULL;


-- 5. Deleted-record verification
--    After deleting an account, confirm the record is actually gone (or soft-deleted as designed).
--    Relates to the "re-registration accepts a deleted email" defect.
SELECT id, email, deleted_at
FROM users
WHERE email = 'test_deleted@example.com';


-- 6. UI counter vs. DB aggregate
--    Validate that a "files: N" counter shown in the UI matches the actual stored rows.
SELECT folder_id, COUNT(*) AS file_count
FROM files
WHERE folder_id = 123
GROUP BY folder_id;


-- 7. JOIN — combine related data for verification
--    List each user with their order count (INNER vs LEFT shows users with zero orders).
SELECT u.id,
       u.email,
       COUNT(o.id) AS order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.email
ORDER BY order_count DESC;


-- 8. Boundary / range check
--    Find values outside an expected valid range (e.g. age must be 0–120).
SELECT id, age
FROM profiles
WHERE age < 0
   OR age > 120;


-- 9. Date consistency
--    A record's "updated" timestamp should never be before its "created" timestamp.
SELECT id, created_at, updated_at
FROM users
WHERE updated_at < created_at;


-- 10. Window function — detect duplicate logical records, keep the latest
--     Useful to find rows that should be unique per user but aren't.
SELECT *
FROM (
    SELECT id,
           user_id,
           created_at,
           ROW_NUMBER() OVER (
               PARTITION BY user_id
               ORDER BY created_at DESC
           ) AS rn
    FROM active_plans
) ranked
WHERE rn > 1;   -- rn > 1 = extra/duplicate plans per user (relates to "restart plan" defect)
