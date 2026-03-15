# Sanity tests for the agent helm chart

Snapshot-based validation for the agent Helm chart. Templates are rendered with `helm template` for each test case in `test-cases/`, split into per-template files, and saved under `snapshots/`. On validation, rendered output is compared against the stored snapshots so any template change is explicit and reviewable in PRs.

## Prerequisites

- `helm` CLI installed
- `npm` installed
- Run `npm install` in this directory

## Usage

### Validate snapshots

```bash
npm run sanity validate
```

Compares currently rendered templates against stored snapshots. Exits with code 1 if any diffs, missing, or extra snapshot files are detected.

### Update snapshots

```bash
npm run sanity update-snapshots
```

Re-renders all test cases and overwrites the `snapshots/` directory. Run this after making intentional changes to the chart templates or test case values.

## Adding a new test case

1. Create a new `<name>.values.yaml` file in the `test-cases/` directory with the Helm values you want to test.
2. Run `npm run sanity update-snapshots` to generate snapshots for the new case.
3. Commit the new values file and the generated `snapshots/<name>/` directory.

## Manually rendering a single test case

```bash
helm template agent ../ -f default.values.yaml -f test-cases/strict-security.values.yaml
```
