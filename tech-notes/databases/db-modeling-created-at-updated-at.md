# created_at / updated_at (Audit Timestamps in Data Modeling)

## What is it?

`created_at` and `updated_at` are two audit (metadata) columns added to almost every table in a relational or document schema.

- **`created_at`**: the moment a row was first inserted. Written once, never changed.
- **`updated_at`**: the moment the row was last modified. Overwritten on every update.

They are part of a broader family of "audit columns" (`created_by`, `updated_by`, `deleted_at`, `version`) whose job is to record the lifecycle of a record rather than the business data itself. The two timestamps answer the two most common operational questions about any row: *when did this come into existence?* and *when did it last change?*

```
  users
  ┌──────────┬───────────┬─────────────────────────┬─────────────────────────┐
  │ id       │ email     │ created_at              │ updated_at              │
  ├──────────┼───────────┼─────────────────────────┼─────────────────────────┤
  │ 1        │ a@x.com   │ 2026-01-04 09:12:33 UTC │ 2026-01-04 09:12:33 UTC │  ← never edited
  │ 2        │ b@x.com   │ 2026-02-11 14:00:01 UTC │ 2026-07-20 08:45:19 UTC │  ← edited later
  └──────────┴───────────┴─────────────────────────┴─────────────────────────┘
                                     │                         │
                              set once on INSERT        rewritten on every UPDATE
```

## Why are people doing this?

The columns are cheap to add and repay themselves constantly:

- **Debugging and forensics**: "when did this record break?" is answerable without a separate log store.
- **Cache invalidation**: `updated_at` is the natural cache key / ETag. If it has not moved, the cache is still valid.
- **Incremental sync / ETL / CDC**: downstream jobs pull only rows where `updated_at > last_run`. This is the backbone of most nightly warehouse loads.
- **Sorting and UX**: "newest first", "recently modified", activity feeds.
- **Optimistic concurrency (weak form)**: detect that a row changed under you since you read it.
- **Compliance / audit trails**: regulators and SOC2/GDPR reviews expect to see record lineage.
- **Retention and cleanup**: TTL jobs delete rows older than N days by `created_at`.

The core reason is that the information is impossible to reconstruct after the fact. If you did not capture the timestamp at write time, it is gone forever. The cost is two columns; the value is an audit trail you never have to rebuild.

## Patterns

### 1. Database-side defaults + trigger (recommended for correctness)

Let the database own the clock. One source of truth, consistent across every application, script, and manual `psql` session.

```sql
CREATE TABLE users (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  email       text NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

`created_at` gets a column `DEFAULT`. `updated_at` needs a `BEFORE UPDATE` trigger because PostgreSQL has no built-in auto-update timestamp (MySQL does: `ON UPDATE CURRENT_TIMESTAMP`).

### 2. Application / ORM-side (recommended for portability)

The framework sets both values in code. Portable, DB-agnostic, easy to test, but every writer must go through the ORM.

```
  Hibernate/JPA   @CreationTimestamp / @UpdateTimestamp  (or @CreatedDate/@LastModifiedDate + @EnableJpaAuditing)
  Rails           automatic on any model with the columns
  Django          auto_now_add=True (created), auto_now=True (updated)
  Sequelize       timestamps: true
  Prisma          @default(now()) / @updatedAt
  GORM            gorm.Model embeds CreatedAt/UpdatedAt/DeletedAt
```

### 3. MySQL native

```sql
created_at timestamp DEFAULT CURRENT_TIMESTAMP,
updated_at timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
```

### 4. Always store UTC, always store the zone

Use `timestamptz` in Postgres (stores an instant, normalized to UTC) rather than `timestamp` (a naive wall-clock with no zone, an ambiguity bomb). Convert to the user's local zone at read time, never at write time.

```
  WRITE:  local input ─► convert to UTC ─► store instant
  READ:   stored UTC  ─► convert to viewer's zone ─► display
```

### 5. Companion columns (the full audit set)

```
  created_at   timestamptz   when
  updated_at   timestamptz   when last
  created_by   bigint/uuid   who (FK to users)
  updated_by   bigint/uuid   who last
  deleted_at   timestamptz   soft delete marker (NULL = live)
  version      int           optimistic-lock counter
```

Common practice is to factor these into a shared base entity / mixin (`Auditable`, `TimestampedModel`, `gorm.Model`) so every table inherits them uniformly.

### 6. Soft delete pairing

`deleted_at IS NULL` means "live". Setting `deleted_at = now()` retires the row while preserving history and foreign-key integrity. Active queries filter `WHERE deleted_at IS NULL`; admin/restore paths ignore the filter.

## Anti-patterns

- **Trusting the application clock across many services**: multiple app servers with clock skew produce out-of-order timestamps. Prefer the DB clock (one clock) when correctness matters.
- **Mixing DB-time and app-time in the same table**: `created_at` from the DB and `updated_at` from the app (or vice versa) makes `updated_at < created_at` possible. Pick one source per table.
- **Using `timestamp` instead of `timestamptz` / not storing UTC**: DST transitions and multi-region deploys silently corrupt ordering and arithmetic. The classic bug: app in one zone, DB in another, timestamps drift by hours.
- **`updated_at` that is not actually maintained**: relying on developers to hand-set it in raw SQL paths. Sooner or later a bulk `UPDATE` or a migration skips it and the column lies. Enforce with a trigger.
- **Treating `updated_at` as a real audit log**: it only tells you *the last* change, not the history. It is not a substitute for an audit table / event log / temporal table when you need *every* change.
- **`updated_at` as the sole optimistic-lock token**: two updates inside the same clock tick (millisecond) can collide undetected. Use a monotonic `version` integer for locking; keep `updated_at` for humans.
- **Bloating "hot" high-write tables**: rewriting `updated_at` on every heartbeat/counter update causes churn (index bloat, extra WAL, MVCC dead tuples). For very hot rows consider not touching `updated_at` on trivial writes.
- **`created_at` mutated by a careless upsert or restore**: `INSERT ... ON CONFLICT DO UPDATE` that overwrites `created_at`, or a data restore that resets it. `created_at` must be immutable.
- **No index despite querying by it**: sync/ETL filter on `updated_at` constantly; without an index those become full scans.
- **Auto-updating `updated_at` on soft delete but hiding it**: `deleted_at` write bumps `updated_at`, confusing "last edited" with "deleted". Decide the semantics explicitly.

## Pros / Cons

### Pros

- **Cheap**: two columns, negligible storage, huge diagnostic value.
- **Universal**: every mature ORM and framework supports them out of the box.
- **Enables incremental sync / CDC / cache invalidation** with almost no extra work.
- **Free forensics**: answers "when" without a dedicated logging system.
- **Foundation for soft delete, retention, and lifecycle policies.**
- **Irreplaceable**: the data cannot be recovered if not captured at write time.

### Cons

- **Only last-write memory**: `updated_at` is not a change history.
- **Write amplification**: every update touches `updated_at`, adding churn on hot tables.
- **Timezone / clock-source footguns**: skew, DST, and `timestamp` vs `timestamptz` cause subtle, hard-to-spot bugs.
- **Consistency burden**: without a DB trigger, discipline across every write path is required and eventually fails.
- **Millisecond collisions** make timestamps unreliable as locking or uniqueness tokens.
- **Indexing cost**: to query by them efficiently you pay for another index to maintain.

## Companies / ecosystems doing this

This is close to universal; the interesting part is *how* each ecosystem bakes it in:

- **Ruby on Rails**: `created_at` / `updated_at` auto-managed on any model that has the columns — arguably popularized the convention.
- **Django**: `auto_now_add` / `auto_now` field options.
- **Spring / Hibernate (Java)**: `@CreatedDate` / `@LastModifiedDate` with `@EnableJpaAuditing`, or `@CreationTimestamp` / `@UpdateTimestamp`.
- **Laravel (Eloquent)**: `timestamps()` migration helper, automatic on save; `SoftDeletes` trait for `deleted_at`.
- **Prisma / Sequelize / TypeORM (Node)**: `@default(now())` / `@updatedAt`, `timestamps: true`, `@CreateDateColumn` / `@UpdateDateColumn`.
- **GORM (Go)**: `gorm.Model` embeds `CreatedAt`, `UpdatedAt`, `DeletedAt`.
- **Supabase / PostgREST**: documented `moddatetime` trigger pattern for `updated_at`.
- **GitHub, Stripe, Shopify** (and effectively every SaaS API): expose `created_at` / `updated_at` (or `created`/`updated`) on public API objects as standard fields.

## Sources

- [Rethinking created_at and updated_at: Are These Fields Still Worth It? — Yedidya Rashi](https://medium.com/@yedidyarashi/rethinking-created-at-and-updated-at-are-these-fields-still-worth-it-85c79984d11d)
- [Best Practices for Database Design: Timestamps and User Metadata — Abdelaziz Dawoud](https://medium.com/@abdelaz9z/best-practices-for-database-design-incorporating-timestamps-and-user-metadata-in-tables-2310527dd677)
- [How to implement CreatedAt and UpdatedAt timestamps in EF Core — bayra.mov](https://bayra.mov/blog/how-to-implement-audit-timestamps-ef-core/)
- [PostgreSQL: now() vs 'NOW'::timestamp vs clock_timestamp() — CYBERTEC](https://www.cybertec-postgresql.com/en/postgresql-now-vs-nowtimestamp-vs-clock_timestamp/)
- [Working with Time in Postgres — Crunchy Data](https://www.crunchydata.com/blog/working-with-time-in-postgres)
- [PostgreSQL timestamps: With or without time zone? — Naiquev](https://www.naiquev.in/postgresql-timestamps-with-or-without-time-zone.html)
- [How to Store Dates in UTC in MySQL — OneUptime](https://oneuptime.com/blog/post/2026-03-31-mysql-store-dates-in-utc/view)
- [Timezone settings for created_at and similar fields — Laravel Daily](https://laraveldaily.com/post/timezone-settings-for-created_at-and-similar-fields)
- [Change tracking and soft delete: audit trails without the boilerplate — DEV](https://dev.to/davidlastrucci/change-tracking-and-soft-delete-audit-trails-without-the-boilerplate-57oc)
- [Implementing Domain-Driven Soft Deletes in Spring Boot with Hibernate Filters and JPA Auditing — Medium](https://medium.com/@nelushgayashan/implementing-domain-driven-soft-deletes-in-spring-boot-with-hibernate-filters-and-jpa-auditing-a8696a7ac185)
- [GORM Soft Delete: updating updated_at automatically — Tailor Tech](https://medium.com/tailor-tech/gorm-soft-delete-how-to-update-the-updated-at-field-automatically-7da7817f796a)
- [Django's auto_now and auto_now_add for auditing timestamps — DEV](https://dev.to/adriennedomingus/django-s-autonow-and-autonowadd-fields-for-auditing-creation-and-modification-timestamps-1je2)
