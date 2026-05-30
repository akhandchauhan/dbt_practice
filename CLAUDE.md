# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repository.

## What this repository is

Two things living side by side:

1. **A dbt project** — [dbt_practice/](dbt_practice/) — dbt Core connected to Google BigQuery. This is where
   actual models, seeds, tests, and docs are built.
2. **A 30-day, self-paced dbt learning course** — [days/](days/) + [plan.md](plan.md) — the curriculum the
   owner is working through to go from "strong SQL, zero dbt" to job-ready analytics engineer.

The course *drives* the dbt project: each day's exercises add to the same `dbt_practice/` project, which
grows from a single mart on Day 1 into a production-grade, documented, CI-tested pipeline by Day 30.

## Repository layout

```
dbt/                              <- workspace root (cwd); CLAUDE.md + plan.md live here
├── CLAUDE.md                     <- this file
├── plan.md                       <- full 30-day curriculum (the master plan)
├── days/                         <- the course, one folder per day
│   └── day-01/
│       ├── 01-concept.md         <- the lesson (~10-15 min read)
│       └── 02-exercises.md       <- hands-on build + challenges (~40 min)
├── dbt_practice/                 <- THE dbt project (all dbt commands run from here)
│   ├── dbt_project.yml
│   ├── seeds/                    <- raw_customers.csv, raw_orders.csv, raw_payments.csv (Jaffle Shop)
│   ├── models/
│   │   ├── staging/jaffle_shop/  <- staging models (currently empty; populated from ~Day 3)
│   │   └── marts/                <- mart models (e.g. top_customers from Day 1)
│   ├── macros/ snapshots/ tests/ analyses/   <- standard dbt dirs (empty placeholders for now)
│   └── README.md
├── logs/                         <- dbt.log from prior runs (NOT gitignored — sits above the project)
├── .vscode/settings.json         <- opens .md as rendered preview by default (workspace-scoped)
└── .gitignore
```

Note: `dbt_practice/target/` and `dbt_practice/dbt_packages/` are dbt-generated and gitignored by the
project's own `.gitignore`.

## The learning course (days/ + plan.md)

- **[plan.md](plan.md) is the master curriculum** for all 30 days — read it to know where any given day sits
  in the arc and why.
- **Each day is two files** under `days/day-NN/`: `01-concept.md` (lesson) then `02-exercises.md` (hands-on).
  Mirror this exact structure when creating new days.
- **Pedagogy (keep to it when authoring days):**
  - *Outcome-first, flaw-driven spiral* — Day 1 ships a real business answer; every later day starts from a
    concrete flaw in the project built so far, and that day's dbt feature is the fix for *that* flaw. Do NOT
    revert to a bottom-up topic march (sources → staging → marts before any payoff).
  - *Challenge-driven* — each day has a Cold-Open "Predict First", a "Break It / Fix It" debugging challenge,
    and a daily scorecard; each week ends with an unaided, timed "Boss Fight".
  - *Lean theory* — the learner is an experienced data engineer with strong SQL. Skip SQL fundamentals; use
    SQL analogies; ≤10-15 min of concept per day.
- There is intentionally **no learning-log file** — the owner opted out of it.

## The dbt project (dbt_practice/)

**All dbt commands run from inside [dbt_practice/](dbt_practice/)** (that's where `dbt_project.yml` is):

- `dbt debug` — verify the BigQuery connection/profile
- `dbt seed` — load the Jaffle Shop CSVs in `seeds/` into BigQuery
- `dbt run` — materialize models (`--select model_name`, `+model`/`model+` for up/downstream)
- `dbt test` — run data tests from `schema.yml`/`_models.yml`
- `dbt build` — seed + run + test + snapshot in DAG order (preferred for a full refresh)
- `dbt compile` — render Jinja → SQL into `target/compiled/` without executing (the go-to for debugging)
- `dbt docs generate` / `dbt docs serve` — build and view the docs site + lineage graph
- `dbt clean` — remove `target/` and `dbt_packages/`

**Materialization defaults** (from `dbt_project.yml`, override per-model with `{{ config(materialized=...) }}`):

| Folder under `models/` | Default materialization |
|---|---|
| `staging` | `view` |
| `intermediate` | `ephemeral` |
| `marts` | `table` |

**Conventions:**
- Reference other models/seeds/sources with `{{ ref('...') }}` / `{{ source('...') }}` — **never hard-code
  table names** across models. dbt uses these to build the DAG.
- Staging models named `stg_<source>__<entity>`; marts named by business entity in plain English.
- `amount` in `raw_payments` is in **cents** (1000 = $10.00); divide by 100 for dollars.

## Profile & environment

- The project's `profile:` is `dbt_practice`. dbt looks it up in `%USERPROFILE%\.dbt\profiles.yml` (NOT in the
  repo). Never commit `profiles.yml`.
- Warehouse: **Google BigQuery Sandbox** (free tier). The practice dataset is `dbt_practice` in **asia-south2**.
  Connection details (project, dataset, region, threads, `maximum_bytes_billed`) live in `profiles.yml`.
- **Weeks 3–4 use `bigquery-public-data.thelook_ecommerce`**, which lives in the **US** multi-region. A single
  BigQuery query cannot read from US and write to asia-south2 — so thelook work uses a separate **US-located
  dataset** (see plan.md, Week 3 Day 1).
- **Sandbox limits to design within:** tables expire after 60 days; ~1 TB/month query cap (cap scans with
  `maximum_bytes_billed` and dev row limits); no BigQuery scheduled queries / Data Transfer / streaming
  (these need billing — Week 4 uses dbt Cloud's free tier to orchestrate instead).
- Platform: **Windows + PowerShell** — give all command examples in PowerShell syntax.

## When working in this repo

- Building a model/test/macro for a lesson? Do it inside `dbt_practice/` following the conventions above.
- Authoring a new day? Create `days/day-NN/01-concept.md` + `02-exercises.md`, follow the flaw-driven,
  challenge-driven pedagogy, and keep it consistent with [plan.md](plan.md).
- Adding a new model subdirectory under `models/`? Mirror the pattern in `dbt_project.yml`'s `models:` block
  to set its default materialization.
