# Day 1 — Exercises & Challenges

> **Week 1 · Day 1 · Hands-on** (~40 min). Read `01-concept.md` first and write down your Cold-Open
> predictions. Run all commands from the **`dbt_practice/`** directory in PowerShell.
> 🏆 Three challenges today. Track your score at the bottom.

---

## 🔨 Build — ship the top-10 customers mart

### Step 0 — Confirm a clean project (1 min)
Your `dbt init` example models are already removed and `dbt_project.yml` already has no `example:` block —
verify, don't assume:

```powershell
dbt compile
```

It should compile with no `example` models. If you ever see an `example:` block under `models:` in
`dbt_project.yml`, delete it.

### Step 1 — Load the raw data (2 min)
```powershell
dbt seed
```
Expected: 3 seeds loaded — `raw_customers`, `raw_orders`, `raw_payments`. Open BigQuery and confirm the three
tables landed in your target dataset (the `dataset:` in your dev target — likely `dbt_practice`).

### Step 2 — Write the model (the real work)
Create the file `models/marts/top_customers.sql`. **Write the SQL yourself first** — you know advanced SQL,
so this is a join + aggregate, not new territory. Requirements:

- Spend per customer = **`sum(raw_payments.amount) / 100.0`** (remember: amount is in **cents**).
- Join path: `raw_customers.id` ← `raw_orders.user_id`, and `raw_orders.id` ← `raw_payments.order_id`.
- Return: `customer_id`, `first_name`, `last_name`, `lifetime_spend_usd`.
- Order by spend descending, **top 10**.
- Reference every seed with `{{ ref('...') }}` — **no hard-coded table names**.
- 🧠 Decide the `status` question from the concept: do you exclude `returned` orders? Make a choice and add a
  comment in the file explaining it.

<details>
<summary>🔒 Reference solution — open only after you've written your own</summary>

```sql
-- models/marts/top_customers.sql
-- Business call: counting ALL payments toward lifetime spend, including orders later returned,
-- because the cash did change hands. (Swap the join to exclude status='returned' if you disagree.)

with payments as (
    select order_id, amount
    from {{ ref('raw_payments') }}
),

orders as (
    select id as order_id, user_id as customer_id
    from {{ ref('raw_orders') }}
),

customers as (
    select id as customer_id, first_name, last_name
    from {{ ref('raw_customers') }}
),

customer_spend as (
    select
        o.customer_id,
        sum(p.amount) / 100.0 as lifetime_spend_usd
    from payments p
    join orders o on p.order_id = o.order_id
    group by 1
)

select
    c.customer_id,
    c.first_name,
    c.last_name,
    cs.lifetime_spend_usd
from customer_spend cs
join customers c on cs.customer_id = c.customer_id
order by cs.lifetime_spend_usd desc
limit 10
```
</details>

### Step 3 — Build it
```powershell
dbt run --select top_customers
```
Green? Good.

### Step 4 — See your answer (the payoff)
In the BigQuery console:
```sql
select * from `your_project.your_dataset.top_customers` order by lifetime_spend_usd desc;
```
You should get **10 rows**. **That's a real business answer, day one.** 🎉

---

## ✅ Cold-Open reveal — check your predictions
- **Object & name:** because `marts:` is configured `+materialized: table` in `dbt_project.yml`,
  `top_customers` is a **TABLE** named `top_customers` (not a view). Did you predict table?
- **DDL:** dbt sent roughly `create or replace table `your_dataset`.`top_customers` as ( <your SELECT> )`.
  See the real thing in **`target/run/dbt_practice/models/marts/top_customers.sql`**.
- **`ref()`:** at compile time dbt replaced `{{ ref('raw_orders') }}` with the fully-qualified
  ``your_project`.`your_dataset`.`raw_orders`` and recorded the dependency. See
  **`target/compiled/dbt_practice/models/marts/top_customers.sql`**.

---

## 💥 Challenge 1 — Break It / Fix It
Make it fail on purpose and learn to read the failure.

1. In `top_customers.sql`, rename `amount` to `amountX` inside the `payments` CTE.
2. `dbt run --select top_customers` — it fails.
3. **Diagnose (write the answers):**
   - Did the error come from **dbt** (compile-time) or **BigQuery** (run-time)? How can you tell from the
     message?
   - Open `target/compiled/dbt_practice/models/marts/top_customers.sql` — the SQL dbt *actually sent*. Is the
     bug visible there?
4. Fix it, re-run green, and write your **one-line prevention rule** (e.g., "compiled SQL in `target/` is the
   source of truth when a run fails, not my `.sql`").

> Why this matters: 90% of dbt debugging is "read the compiled SQL, not the template." You just built the
> reflex on day one.

---

## 📦 Deliverable
- [ ] `top_customers` table live in BigQuery, returning 10 customers descending by `lifetime_spend_usd`.
- [ ] The 10-row result pasted/screenshotted somewhere you keep notes.
- [ ] Every seed referenced via `ref()`; zero hard-coded table names.
- [ ] A comment in the model stating your `returned`-orders business decision.

## ✅ Validation checklist
- [ ] `dbt seed` created 3 tables in BigQuery
- [ ] `dbt run --select top_customers` is green
- [ ] Querying `top_customers` returns exactly 10 rows, sorted by spend desc, spend in **dollars** (not cents)
- [ ] You can explain, in one sentence, why `ref()` beats a hard-coded table name
- [ ] Challenge 1: you can say whether the error was dbt vs BigQuery, and your prevention rule

## ⚠️ Common mistakes (don't lose points to these)
- **Cents bug:** forgetting `/100.0` → spend looks 100× too big. (1000 = $10.00.)
- **Fan-out:** joining customers→orders→payments and then `sum` without grouping correctly can double-count;
  aggregate payments per order/customer *before* the final join, as in the reference.
- **Looking for `profiles.yml` in the repo** — it lives at `%USERPROFILE%\.dbt\profiles.yml`.
- **YAML tabs** in `dbt_project.yml` — spaces only; dbt rejects tabs.

## 💪 Challenge 2 — Stretch (optional)
1. Add `{{ config(materialized='view') }}` at the top of `top_customers.sql`, `dbt run` again, and check the
   BigQuery object — is it now a **view**? Read the new DDL in `target/run/...`. Articulate: when would you
   want this mart as a view vs a table? (Cost on read vs cost on build.)
2. Remove the config so it inherits `table` from `dbt_project.yml` again.

---

## 🏆 Day 1 Scorecard
- [ ] **Challenge 0 — Predict First:** got the table-vs-view prediction right
- [ ] **Challenge 1 — Break/Fix:** diagnosed dbt-vs-BigQuery + wrote prevention rule
- [ ] **Challenge 2 — Stretch:** view/table tradeoff articulated *(bonus)*

Score: **___ / 2** core (+1 bonus). Cleared 2/2? You shipped a real analytics answer and can debug a failed
run on day one.

---

## ➡️ Tomorrow — Day 2 preview & the flaw you're leaving
Your mart reads raw seeds directly. **Day 2 mission:** *"Raw tables got renamed overnight — don't let it break
us."* You'll declare the raw data as dbt **`sources`** (`_sources.yml` + `source()`), decouple your pipeline
from raw, and even configure freshness so dbt warns you when raw data goes stale.
**Day 2 cold-open:** predict which part of your pipeline breaks *first* when a raw column disappears.
