# 30-Day dbt Masterplan — dbt Core + BigQuery, ~1 hr/day

Goal: from **strong SQL, zero dbt** → **job-ready analytics engineer** who can build, test, document, deploy,
and optimize a production-grade dbt pipeline on BigQuery — ending with a public, portfolio-worthy capstone.

## How this plan works

- **Two files per day** under [days/](days/): `day-NN/01-concept.md` (lesson, ≤10–15 min) → `02-exercises.md`
  (hands-on build + challenges, ~40 min). All dbt work happens in [dbt_practice/](dbt_practice/).
- **The spine — outcome-first, flaw-driven spiral.** Day 1 ships a *real business answer*. Every later day
  starts from a **concrete flaw** in the pipeline you've built so far, and that day's dbt feature is the fix
  for *your* flaw. The same project deepens over 30 days — no bottom-up topic march, no payoff-free plumbing.
- **Challenge-driven mechanics, every day:** a Cold-Open *Predict First*, a *Break It / Fix It* debugging
  challenge, a daily scorecard, and an end-of-week **Boss Fight** (unaided, timed).

## Environment

- dbt Core · BigQuery **Sandbox** (free) · Windows PowerShell · working `profiles.yml`.
- **Weeks 1–2:** Jaffle Shop seeds (already in `dbt_practice/seeds/`). **Weeks 3–4 + capstone:**
  `bigquery-public-data.thelook_ecommerce`.
- **Region gotcha:** thelook lives in **US**; your practice dataset is **asia-south2**. A query can't read US
  and write asia-south2 — Week 3 Day 1 creates a **US-located dataset** for thelook work.
- **Sandbox limits:** 60-day table expiry · ~1 TB/month query cap (cap scans with `maximum_bytes_billed` +
  dev limits) · no native scheduled queries/streaming (Week 4 orchestrates via dbt Cloud's free tier).

## Anchor resources (one per topic, not all)

- [dbt Fundamentals](https://learn.getdbt.com/courses/dbt-fundamentals) · [dbt + BigQuery quickstart](https://docs.getdbt.com/guides/bigquery)
- [How we structure our dbt projects](https://docs.getdbt.com/best-practices/how-we-structure/1-guide-overview) · [BigQuery configs](https://docs.getdbt.com/reference/resource-configs/bigquery-configs)
- [dbt-utils](https://github.com/dbt-labs/dbt-utils) · [dbt-project-evaluator](https://github.com/dbt-labs/dbt-project-evaluator) (self-grade the capstone)
- [Analytics Engineer cert syllabus](https://www.getdbt.com/certifications/analytics-engineer-certification-exam) (topic checklist even if not sitting the exam)

---

## Week 1 — Ship it, then make it real (Jaffle Shop)

A working mart on Day 1; each day fixes its next flaw.

| Day | Mission (business question) | Flaw it fixes | New dbt skill | Deliverable |
|---|---|---|---|---|
| 1 | Top 10 customers by lifetime spend — in BigQuery, today | — (greenfield) | model = saved `SELECT`, `dbt seed`, `dbt run`, `ref()` | `top_customers` table live, 10 rows |
| 2 | Raw tables got renamed overnight — don't let it break us | Day 1 hard-references raw seeds | `sources`, `source()`, seeds-vs-sources | `_sources.yml` declared; mart reads via `source()` |
| 3 | A second question needs the same clean customer/order logic | Day 1 is one monster model | staging layer (`stg_<src>__<entity>`), DAG via `ref()` | `stg_*` views; mart rebuilt on top of them |
| 4 | Prove the spend number isn't a lie | nothing guarantees correctness | tests: `unique`/`not_null`/`relationships`/`accepted_values` + 1 singular | `dbt test` green; a broken row gets caught |
| 5 | Make the daily rebuild cheap and fast | mart fully rebuilds every run | materializations: view/table/ephemeral (+ incremental teaser), cost | one of each live; cost difference measured |
| 6 | Onboard a teammate to this DAG in 5 minutes | nobody can read the pipeline | docs + lineage (`dbt docs generate`/`serve`), descriptions | doc site with full lineage |
| 7 | **🏆 Boss Fight:** "Which products drive repeat purchases?" | — | build a full sources→staging→mart slice unaided + timed | green `dbt build`, ≥2 tests, every column described |

---

## Week 2 — Make it powerful & reusable (Jaffle Shop)

| Day | Mission | Flaw it fixes | New dbt skill | Deliverable |
|---|---|---|---|---|
| 8 | The same CASE logic is copy-pasted across 3 models | repetition, drift risk | Jinja (`{{ }}` vs `{% %}`, vars, `if`/`for`) | a model generated via a `for` loop |
| 9 | "cents → dollars" math is rewritten everywhere | duplicated transforms | custom **macro** (`cents_to_dollars`) | 1 reusable macro used in ≥1 model |
| 10 | We keep reinventing surrogate keys & date spines | wheel-reinvention | **packages** — `dbt_utils` (`generate_surrogate_key`, `date_spine`) | `packages.yml` + `dbt deps`; surrogate keys in marts |
| 11 | "What did this customer's status look like last month?" | history is lost on overwrite | **snapshots** (SCD Type 2) | snapshot table with `dbt_valid_from/to` |
| 12 | Is our raw data even fresh? | stale data passes silently | **source freshness** (`loaded_at_field`, warn/error) | freshness configured + `dbt source freshness` |
| 13 | `unique`+`not_null` can't express our business rules | weak guarantees | **custom generic tests** (e.g. `positive_value`) | 1 custom generic test reused across ≥2 models |
| 14 | **🏆 Boss Fight:** make the project portfolio-grade | messy structure | refactor to the dbt-Labs `staging/intermediate/marts` layout | clean structure pushed to a private GitHub repo; reusable macro + custom test live |

---

## Week 3 — Make it production-scale (thelook_ecommerce, BigQuery)

Real data, real cost. This is where the BigQuery-specific, job-defining skills live.

| Day | Mission | Flaw it fixes | New dbt skill | Deliverable |
|---|---|---|---|---|
| 15 | Build on 200M+ real rows without blowing the sandbox cap | toy data only | add thelook **source** (US dataset), bounded dev (`limit`, `maximum_bytes_billed`), `stg_thelook_*` | staging on real data, costs capped |
| 16 | Our queries scan the whole table | full-table scans | **partitioning** (`partition_by` on a date) | partitioned table; bytes-scanned compared |
| 17 | Filtered queries still scan too much | no data pruning on filters | **clustering** (`cluster_by`) | clustered + partitioned mart |
| 18 | Rebuilding all history every run is wasteful | full refresh every time | **incremental models** (`merge`, `is_incremental()`, `unique_key`) | model processing only new rows on re-run |
| 19 | Merge on huge partitioned data is still costly | inefficient incremental | **`insert_overwrite` with partitions** (BQ production pattern) | overwrites only specific date partitions |
| 20 | Downstream consumers break when we change a column | silent schema breakage | **model contracts** + **versioning** | 1 contract-enforced, typed, versioned model |
| 21 | **🏆 Boss Fight:** prove incremental efficiency | — | + **exposures** & **model groups/access** | incremental mart re-scans **<5%** on re-run; `_exposures.yml` declares a dashboard |

---

## Week 4 — Make it deployable + capstone (thelook_ecommerce)

| Day | Mission | Flaw it fixes | New dbt skill | Deliverable |
|---|---|---|---|---|
| 22 | dev and prod can't share one dataset | no env separation | **environments** (dev/prod targets, `generate_schema_name`) | `dbt run --target prod` lands in a separate dataset |
| 23 | Git history is a mess; secrets at risk | sloppy versioning | git workflow + `.gitignore` hygiene (`target/`, `logs/`, `profiles.yml`), PR-per-feature | clean history; nothing secret tracked |
| 24 | Nothing checks my pull requests | no CI safety net | **CI with GitHub Actions** (`dbt build --select state:modified+`, slim CI) | `.github/workflows/dbt-ci.yml` runs on every PR |
| 25 | I want a hosted IDE + scheduling | local-only | **dbt Cloud onboarding** (free Developer tier; connect GitHub + BigQuery) | project loads green in the Cloud IDE |
| 26 | Builds should run themselves nightly | manual runs | **dbt Cloud job** (cron) + freshness + failure notifications | 1 scheduled production job running daily |
| 27 | Stakeholders need always-on docs + auto-checked PRs | local docs only | **Cloud hosted docs** + **Cloud CI** (deferred state) | hosted docs URL; CI run on a dummy PR |
| 28 | Capstone kickoff — design before you build | no target architecture | dimensional design on thelook (facts + dims) | one-page design doc in the repo `README` |
| 29 | Capstone build — assemble the full pipeline | — | sources→staging→intermediate→marts w/ partitioning, ≥1 incremental, tests, exposures, dbt_utils, docs | full DAG building green |
| 30 | **🏆 Boss Fight:** ship it public | — | polish: README + architecture diagram, self-grade with `dbt-project-evaluator`, lineage screenshots | **public portfolio repo**; a stranger clones + `dbt build` green with only `profiles.yml` |

---

## Weekly verification (don't advance until true)

- **Week 1:** `dbt build` green end-to-end; `dbt docs serve` shows full lineage from a mart back to raw; you
  can justify view-vs-table per model.
- **Week 2:** a custom macro and a custom generic test are each reused in ≥2 places; `dbt deps` installs
  `dbt_utils` cleanly; a snapshot run twice produces no spurious new rows.
- **Week 3:** re-running the Day-18/19 incremental mart scans **<5%** of the full-build bytes; you can explain
  `merge` vs `insert_overwrite` and read the BQ query plan.
- **Week 4:** GitHub Actions CI passes on a PR; a scheduled dbt Cloud job has run at least once; the capstone
  repo is public and self-contained.

## Daily habit (baked into the hour)

1. Open `dbt_practice/`; `dbt build` to confirm a green baseline.
2. Read `day-NN/01-concept.md` (≤10–15 min) and write your Cold-Open prediction.
3. Do `day-NN/02-exercises.md` — build, then the Break-It/Fix-It challenge (~30–40 min).
4. `dbt build && dbt test`; commit with a meaningful message.
5. Log your daily scorecard (challenges cleared / attempted) and the flaw you're leaving for tomorrow.

## Deliberately skipped (and why)

- **Python models** — cert topic, rare in day-to-day BQ work; add 1 day if you sit the exam.
- **Microbatch incremental** — newer; pick up after Day 19 once vanilla incremental is solid.
- **Semantic Layer / MetricFlow** — moving target, not needed for "job-ready"; revisit if a job posting wants it.
- **Snowflake/Redshift specifics** — BigQuery-only, since that's the target warehouse.
