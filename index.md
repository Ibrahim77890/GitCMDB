# GitCMDB: Bash, Linux, and Git Portfolio Project

GitCMDB is a Git-backed configuration management database built entirely from Bash scripts, standard Linux utilities, and text-based documents. It is designed to show practical DevOps skill rather than generic scripting skill. The project demonstrates Linux filesystem design, safe shell scripting, Git-based state history, query pipelines, locking, validation, and operational documentation.

The point of the project is not to imitate PostgreSQL or SQLite. The point is to build a production-style system that solves a real DevOps problem: tracking infrastructure state in a way that is auditable, reproducible, searchable, and easy to operate from the command line.

## What GitCMDB Is

GitCMDB is a lightweight configuration and asset registry for infrastructure teams. It stores servers, environments, services, networks, compliance records, and deployment metadata as JSON or YAML files in a structured directory tree. Every change is committed to Git so the full history is preserved.

This makes the system useful as both a tool and a portfolio artifact:

1. It shows you understand Bash scripting and shell safety.
2. It shows you can design Linux-native storage layouts.
3. It shows you can use Git as an audit log and replication layer.
4. It shows you can build search and reporting workflows with grep, rg, awk, sed, jq, and xargs.
5. It shows you know how to document, test, benchmark, and operate a system like an experienced DevOps engineer.

## The Core Idea

The project should answer four questions well:

1. What assets exist?
2. What is their current state?
3. How did the state change over time?
4. How can operators query and validate it quickly from Bash?

If you can answer those questions cleanly, the project looks credible to hiring managers.

## Recommended Architecture

Use a filesystem-first design instead of a single flat file. Each object is stored as a separate document so you can search, diff, validate, and version it independently.

```text
gitcmdb/
├── bin/
│   ├── gitcmdb
│   └── gitcmdb-init
├── lib/
│   ├── common.sh
│   ├── store.sh
│   ├── query.sh
│   ├── txn.sh
│   └── validate.sh
├── data/
│   ├── prod/
│   │   ├── us-east-1/
│   │   │   ├── hosts/
│   │   │   │   ├── srv-01.json
│   │   │   │   └── srv-02.json
│   │   │   ├── networks/
│   │   │   │   └── core.json
│   │   │   └── services/
│   │   │       └── api.json
│   └── staging/
├── schemas/
│   ├── host.schema.json
│   ├── network.schema.json
│   └── service.schema.json
├── docs/
│   ├── architecture.md
│   ├── usage.md
│   ├── query-examples.md
│   ├── runbook.md
│   └── benchmarking.md
├── tests/
│   ├── test-install.sh
│   ├── test-query.sh
│   ├── test-write.sh
│   └── fixtures/
├── scripts/
│   ├── seed-data.sh
│   ├── benchmark.sh
│   └── export-report.sh
├── man/
│   └── gitcmdb.1
├── .gitignore
├── README.md
└── install.sh
```

## What Each Major File Should Contain

### README.md

This is the first file recruiters will read. It should explain the project in plain language and prove it is a serious systems project.

Include:

1. One-paragraph summary of GitCMDB.
2. Key features.
3. Architecture overview.
4. Installation steps.
5. Example commands.
6. Screenshots or terminal transcripts if available.
7. A section called why this exists that ties the project to DevOps use cases.

Suggested README sections:

```text
# GitCMDB
## Overview
## Features
## Architecture
## Quick Start
## Example Queries
## Write Operations
## Validation
## Benchmarking
## Roadmap
```

### install.sh

This is the bootstrap installer.

It should:

1. Verify dependencies: bash, git, jq, awk, sed, grep, rg, coreutils, flock.
2. Create the directory structure.
3. Initialize Git if the repository is not yet initialized.
4. Set safe permissions.
5. Create default config files.0
6. Print next steps for the user.

It should fail fast with safe shell settings such as `set -euo pipefail` and use clear error messages.

### bin/gitcmdb

This is the main CLI entrypoint.

It should parse commands like:

```text
gitcmdb init
gitcmdb add host srv-01 --env prod --region us-east-1
gitcmdb update host srv-01 --set status=healthy
gitcmdb query hosts --filter 'status=active'
gitcmdb history host srv-01
gitcmdb validate
```

This file should stay small and delegate to library scripts in lib/.

### lib/common.sh

This should contain shared shell utilities used by all scripts.

Include:

1. Logging helpers.
2. Error handling helpers.
3. Path resolution helpers.
4. Temporary file cleanup helpers.
5. Dependency checks.

### lib/store.sh

This should contain filesystem read and write helpers.

Include:

1. Object path resolution.
2. Object creation.
3. Object update.
4. Object deletion.
5. Safe temp-file write logic.
6. Atomic move operations.

### lib/txn.sh

This should contain transaction and locking logic.

Include:

1. flock acquisition.
2. Commit creation.
3. Rollback or cleanup on failure.
4. Commit metadata formatting.
5. Git hooks or post-write actions.

### lib/query.sh

This should contain all read-only search and reporting logic.

Include:

1. Fast file search with rg.
2. Structured extraction with jq.
3. Aggregations with awk.
4. Tabular output formatting.
5. Optional JSON output mode.

### lib/validate.sh

This should validate schema and operational correctness.

Include:

1. JSON schema checks.
2. Required field validation.
3. Naming convention validation.
4. Environment path validation.
5. Duplicate object detection.

### schemas/*.json

These files define the shape of the data.

For example, host.schema.json should define fields such as:

1. hostname
2. environment
3. region
4. ip_address
5. role
6. status
7. kernel
8. owner
9. tags

This is important because it shows your system is not just a pile of text files. It has contracts.

### docs/architecture.md

This should explain the system design at a higher level.

Cover:

1. Why Bash instead of a compiled service.
2. Why Git acts as the state history layer.
3. Why file locking is required.
4. How the directory layout maps to infrastructure.
5. Tradeoffs and limitations.

### docs/usage.md

This should provide operator-facing instructions.

Cover:

1. Install.
2. Initialize.
3. Add objects.
4. Query objects.
5. Update objects.
6. Delete objects.
7. Export data.

### docs/query-examples.md

This should show the Bash pipeline strength of the project.

Examples to include:

1. Find all active hosts in production.
2. Find hosts on a vulnerable kernel.
3. Count hosts by region.
4. List services with missing owners.
5. Aggregate CPU or memory totals.

### docs/runbook.md

This should make the project feel operationally real.

Cover:

1. Backup and restore.
2. Recovery from a bad commit.
3. How to inspect state at a previous revision.
4. How to handle lock contention.
5. How to rotate logs.
6. How to troubleshoot corrupted records.

### docs/benchmarking.md

This is where you show performance discipline.

Include:

1. Dataset size.
2. Command used to generate data.
3. Query patterns tested.
4. Results from Bash pipelines.
5. Comparison against SQLite or another baseline.
6. Notes on where Bash is strong and where it is not.

### scripts/seed-data.sh

This script should generate realistic test data.

It should:

1. Create hundreds or thousands of host documents.
2. Vary regions, roles, kernels, statuses, and owners.
3. Keep the output deterministic if seeded.

This is important for reproducible benchmarking.

### scripts/benchmark.sh

This script should run repeatable performance tests.

Suggested measurements:

1. Query latency for exact matches.
2. Query latency for regex-style searches.
3. Aggregation latency by region.
4. Write latency with locking enabled.
5. Git commit overhead.

### scripts/export-report.sh

This script should generate a human-readable report from the database.

It can output:

1. Markdown.
2. CSV.
3. JSON.
4. Table-formatted terminal output.

## Data Model

Keep the data model simple and realistic.

Recommended object types:

1. Host
2. Service
3. Network
4. Environment
5. Compliance record
6. Deployment event

Example host document:

```json
{
  "hostname": "srv-01",
  "environment": "prod",
  "region": "us-east-1",
  "role": "api",
  "ip_address": "10.10.1.21",
  "status": "active",
  "kernel": "6.1.0",
  "owner": "platform",
  "tags": ["linux", "critical", "web"]
}
```

## Recommended Features

To make the project look senior, do not stop at CRUD.

Build these features:

1. Atomic writes with temp files and mv.
2. Exclusive locks with flock.
3. Git commit per transaction.
4. Read queries that support filtering and aggregation.
5. History lookup by commit hash or tag.
6. Schema validation before writes.
7. Deterministic data seeding.
8. Benchmark mode.
9. Export mode.
10. Clear operator docs.

## Step-By-Step Build Plan

### Phase 1: Define the scope

Decide the first release should only manage hosts.

Your first version should support:

1. Initialize repository layout.
2. Add a host record.
3. Update a host record.
4. Delete a host record.
5. Query hosts.
6. View history.

Do not start with every object type at once.

### Phase 2: Build the directory layout

Create the data tree first.

Use directories for environment and region, then object files for assets.

For example:

```text
data/prod/us-east-1/hosts/srv-01.json
data/prod/us-east-1/services/api.json
```

This keeps the storage model simple and easy to search.

### Phase 3: Build safe shell foundations

Every script should use strict shell behavior.

Use the following practices everywhere:

1. set -euo pipefail
2. IFS handling where needed
3. trap for cleanup
4. quoted variables
5. explicit dependency checks

This shows real Bash discipline.

### Phase 4: Build the write path

The write path is the most important part.

Implement the order below:

1. Validate input.
2. Resolve output path.
3. Acquire lock.
4. Write to a temp file.
5. Validate the temp file.
6. Replace the original file atomically.
7. Stage and commit in Git.
8. Release lock.

This sequence matters because it demonstrates operational correctness.

### Phase 5: Build the query path

Add commands for searching and aggregating.

Implement patterns like:

1. Exact path reads for specific objects.
2. rg for file discovery.
3. jq for field extraction.
4. awk for counts and totals.
5. xargs for parallel batching when safe.

Keep read commands side-effect free.

### Phase 6: Add history and replication behavior

Use Git as the state timeline.

Support these user stories:

1. Show last change to an object.
2. Show all commits affecting a region.
3. Restore an object from a previous commit.
4. Push changes to a remote repository.
5. Pull changes for a replica.

This is the feature that makes the project feel uniquely DevOps-focused.

### Phase 7: Add validation and reporting

Build schema checks and human-readable reports.

Support:

1. Invalid JSON detection.
2. Missing field detection.
3. Duplicate hostname detection.
4. Policy checks.
5. Summary reports by environment and region.

### Phase 8: Add benchmarks

You need numbers to make the portfolio credible.

Benchmark:

1. Small dataset queries.
2. Large dataset queries.
3. Writes under lock.
4. Git commit cost.
5. Export generation time.

Document the methodology, not just the raw result.

## Suggested CLI Commands

Design the interface to feel like a real operational tool.

```text
gitcmdb init
gitcmdb add host --file host.json
gitcmdb get host srv-01
gitcmdb update host srv-01 --set status=healthy
gitcmdb delete host srv-01
gitcmdb query hosts --env prod --status active
gitcmdb history host srv-01
gitcmdb validate
gitcmdb export --format markdown
gitcmdb benchmark
```

## Example Bash Query Ideas

These are strong examples for the portfolio because they show pipeline thinking.

```bash
rg -l '"status": "active"' data/prod |
  xargs jq -r 'select(.kernel == "6.1.0") | .hostname'
```

```bash
find data/prod -name '*.json' -print0 |
  xargs -0 jq -r '.region' |
  awk '{count[$1]++} END {for (region in count) print region, count[region]}'
```

```bash
jq -r '.ip_address' data/prod/us-east-1/hosts/*.json
```

## Security And Reliability Notes

If you want the project to look senior, mention the limits honestly.

Be explicit about:

1. Bash is excellent for orchestration and text processing, not for heavy relational workloads.
2. Git is a strong audit trail, not a substitute for a true transactional database.
3. File locks help concurrency, but they do not solve every distributed systems problem.
4. The design is intentional because the goal is operational transparency and portability.

That honesty increases credibility.

## Portfolio Story

When you present the project, frame it like this:

1. I designed a Linux-native CMDB using Bash, Git, and standard utilities.
2. I treated Git as an immutable change journal and audit layer.
3. I enforced safe write operations with file locks and atomic moves.
4. I built query pipelines with rg, jq, awk, sed, and xargs.
5. I documented the system like an operational product with install, usage, runbook, and benchmark docs.

That story makes the project sound like DevOps engineering, not hobby scripting.

## What To Show In Your Portfolio

Show the following artifacts:

1. A clean repository tree.
2. The README.
3. The architecture doc.
4. The install script.
5. A few real terminal sessions.
6. A benchmark report.
7. A sample Git history showing state changes.
8. A restore or rollback demonstration.

## Final Delivery Checklist

Before you call the project finished, verify that all of these exist:

1. install.sh works from a fresh clone.
2. gitcmdb init creates the layout.
3. gitcmdb add and gitcmdb update perform atomic writes.
4. gitcmdb query returns useful output.
5. gitcmdb history shows state changes.
6. gitcmdb validate catches bad documents.
7. scripts/benchmark.sh produces measurable results.
8. docs/ contains a full operator-facing story.
9. README.md explains the project clearly.
10. The project feels like a system, not a script dump.

## Recommended Execution Order

If you want the fastest path to a strong portfolio piece, build in this order:

1. Write README.md and docs/architecture.md first.
2. Create the directory structure.
3. Build install.sh.
4. Build the main CLI entrypoint.
5. Implement host storage and writes.
6. Add query commands.
7. Add validation.
8. Add Git history features.
9. Add benchmarks.
10. Polish docs and examples.

## Conclusion

GitCMDB is a strong portfolio project because it combines Linux filesystem design, Bash scripting, Git history, text-processing pipelines, and operational thinking into one coherent system.

If you build it cleanly and document it well, it will read like the work of someone who understands DevOps fundamentals and can ship practical automation, not just write shell one-liners.