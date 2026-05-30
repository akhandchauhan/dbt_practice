# Day 1 — Ship a real answer in hour one

> **Week 1 · Day 1 · Concept** (~10 min read). Then do `02-exercises.md`.
> Format: this course is *outcome-first*. You build something a business cares about **today**, and every
> later day fixes a real flaw in the thing you already built. No bottom-up plumbing march.

---

## 🎯 The Mission

Leadership asks: **"Who are our top 10 customers by lifetime spend?"**
By the end of this hour, that answer lives in BigQuery as a dbt model anyone on the team can query.

No setup theater — your `profiles.yml` already works. You go straight to producing value.

---

## 🔮 Cold-Open Challenge — *Predict First* (write your answers before you build)

You're about to create one file, `models/marts/top_customers.sql`, containing a `SELECT` that sums each
customer's payments and returns the top 10. Before you run anything, **commit to predictions**:

1. After `dbt run`, **what object appears in BigQuery, and what's it called?** (Hint: look at the `marts:`
   block in `dbt_project.yml` before you answer.)
2. **What exact DDL** do you think dbt sends to BigQuery — write the first line.
3. Your SQL references `{{ ref('raw_orders') }}`, not the full `project.dataset.raw_orders`. **What does dbt
   do with `ref()` at compile time?**

You'll check these against reality at the end of `02-exercises.md`. Predicting *before* seeing the answer is
the whole point — it surfaces exactly where your mental model is wrong.

---

## The concept (only what this mission needs)

**dbt is the "T" in ELT.** It doesn't extract or load. You write `SELECT` statements; dbt wraps each one in
DDL (`CREATE TABLE/VIEW ... AS <your select>`) and runs them against BigQuery **in dependency order**.

**Your one mental anchor for the whole course — a model is a saved `SELECT`:**

```
models/marts/top_customers.sql   ──dbt run──►   CREATE TABLE top_customers AS (<your SELECT>)
```

You own the `SELECT`. dbt owns the boilerplate `CREATE ... AS`, the ordering, and the warehouse plumbing.

**Today's fastest path to data — seeds.** dbt's `dbt seed` loads small CSVs straight into the warehouse as
tables. Your `seeds/` folder already has the three Jaffle Shop files:

| Seed | Columns | Notes |
|---|---|---|
| `raw_customers` | `id, first_name, last_name` | one row per customer |
| `raw_orders` | `id, user_id, order_date, status` | `user_id` → a customer's `id`; `status` ∈ returned/completed/… |
| `raw_payments` | `id, order_id, payment_method, amount` | `order_id` → an order's `id`; **`amount` is in CENTS** (1000 = $10) |

So the join path to "spend per customer" is: **customers → orders (`user_id`) → payments (`order_id`)**, then
`sum(amount)/100` per customer. (Notice: *payments have no status* — only orders do. Keep that straight.)

**`ref()` is dbt's superpower.** Writing `{{ ref('raw_orders') }}` instead of a hard-coded table name lets
dbt (a) build a dependency graph so it runs things in the right order, and (b) swap the real table name per
environment (dev vs prod dataset). You never hard-code table names in dbt. Ever.

**The loop you'll live in today:**

```
dbt seed                       # load the 3 CSVs into BigQuery
dbt run --select top_customers # compile your SELECT → CREATE TABLE AS → run it
# then query top_customers in BigQuery
```

(`dbt compile` renders Jinja→SQL into `target/compiled/...` *without* touching BigQuery — your go-to for
"what did dbt actually send?" debugging. You'll use it in the Break-It challenge.)

---

## 🤔 Socratic questions (answer in your head before exercises)

1. The same `SELECT` materialized as a **view** vs a **table**: how does the emitted DDL differ, and which one
   costs BigQuery bytes *every time someone queries it* vs *once at build time*?
2. You wrote `ref('raw_orders')`, not `dbt_practice.raw_orders`. Name **two** things dbt can now do that it
   couldn't with the hard-coded name.
3. `dbt run` fails with a column error. Do you open your `.sql` file first, or `target/compiled/...`? Why?
4. Business judgment: `raw_orders.status` can be `returned`. **Should a returned order's payment count toward
   "lifetime spend"?** There's no single right answer — decide, and be ready to defend it.

---

## 🪤 The flaw we leave on purpose (sets up Day 2)

Today your model reads the raw seed tables directly. That's fine to ship fast — but it means **the moment raw
data changes shape (a renamed column, a new source system), your mart breaks with no warning.** That fragility
is tomorrow's mission: you'll introduce dbt **`sources`** so the pipeline is decoupled from raw and can even
alert you when raw data goes stale. For now: ship it, then we harden it.

➡️ Now open **`02-exercises.md`** and build.
