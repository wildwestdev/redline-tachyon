# PROJECT_RULES.md (TEMPLATE)

## Purpose

This file defines repository-specific overrides and configuration for the Swift Agent framework.

Global rules are defined in:
swift-agent/global/GLOBAL_RULES.md

This file is intentionally aligned to the current checked-in repository structure.
Where the repository does not yet meet the global standard, the gap must be
surfaced honestly through doctor and gate checks rather than hidden.

This file must define ONLY:
- project-specific overrides
- concrete commands
- paths and identifiers
- deviations from global defaults (with justification)

---

## 1. Project Identity

- Project Name: `Speed Demon`
- Bundle Identifier: `au.com.nickelrose.speed-demon`
- Repository Type: hybrid

Rationale:
- the repository contains a checked-in Xcode project
- the repository also contains `Package.swift`
- Apple app build ownership remains with the Xcode project

---

## 2. Current Repository Structure

Top-level structure:
- `AGENTS.md`
- `SPEC.md`
- `README.md`
- `LICENSE`
- `Package.swift`
- `SpeedDemon.xcodeproj`
- `Scripts/`
- `Sources/`
- `Tests/`
- `Widget/`
- `docs/`

Xcode project details:
- canonical project file: `SpeedDemon.xcodeproj`
- shared schemes:
  - `SpeedDemon`

Current source layout:
- `Sources/App`
- `Sources/Features`
- `Sources/Glass UI`
- `Sources/Models`
- `Sources/Services`

Current feature layout:
- `Sources/Features/Disclaimer`
- `Sources/Features/History`
- `Sources/Features/Settings`
- `Sources/Features/SpeedDisplay`

Current resource layout:
- `Sources/Assets.xcassets`
- `Widget/Assets.xcassets`

---


## 3. Xcode Project Ownership

- Canonical project file: SpeedDemon.xcodeproj
- Project MUST be created manually at project start
- Project file MUST be committed to the repository

Required structure:
- SpeedDemon.xcodeproj/xcshareddata/xcschemes

Agents MUST NOT:
- regenerate or replace the Xcode project file
- rely on xcuserdata

---

## 4. Versioning Rules

Version source of truth:
- MARKETING_VERSION → Xcode project
- CURRENT_PROJECT_VERSION → Xcode project

### Rules

- Major/Minor versions:
  - manually incremented only
  - must not be modified by agents

- Build number:
  - MUST be incremented before every build
  - MUST NOT be stored in external config

### Build Number Script

./Tools/increment_build_number.sh

Agents MUST run this before build unless explicitly instructed otherwise.

---

## 5. Build Configuration

Default Scheme:
SpeedDemon

Project File:
SpeedDemon.xcodeproj

---

## 6. Artifact Locations (STANDARD)

build/artifacts/
build/latest/
build/runs/
build/snapshots/
build/tests/
build/validation/

### Artifact Retention and Compatibility Mirrors

The repository distinguishes between:

- canonical retained execution artifacts
- compatibility mirror locations

#### Canonical Execution Record

The authoritative retained output for every script execution is:

```text
build/runs/<run-id>/
```

This directory is the canonical execution record and MUST contain:
- validation outputs
- logs
- summaries
- resolved configuration snapshots
- generated artifacts
- test outputs

Each run directory MUST remain self-contained and auditable.

Scripts MUST treat the run directory as the source of truth.

---

#### Compatibility Mirrors

To preserve compatibility with:
- legacy tooling
- editor integrations
- downstream scripts
- external automation
- historical repository expectations

selected outputs MAY also be mirrored into stable convenience paths:

```text
build/validation/
build/tests/
build/artifacts/
build/latest/
```

These mirror locations are convenience views only.

They MUST NOT:
- become the authoritative retained execution record
- contain unique state unavailable in the run directory
- diverge from canonical outputs
- be treated as immutable historical archives

---

#### Latest Symlink

Where supported, the repository MAY maintain:

```text
build/latest
```

as a convenience pointer to the most recent run directory.

This exists purely for:
- operator convenience
- editor integration
- rapid inspection workflows

The symlink MUST NOT replace the canonical run structure.

---

#### Snapshot Retention

Where snapshot validation is implemented:

```text
build/snapshots/
```

may contain:
- baseline snapshots
- validation snapshots
- comparison outputs

Snapshot retention policies must remain deterministic and repository-owned.

---

#### Architectural Intent

This structure ensures:
- deterministic retention
- reproducible validation
- auditability
- backwards compatibility
- stable automation integration
- clean separation between canonical outputs and convenience mirrors


---

## 7. Script Contract Rules (MANDATORY)

This repository uses a standardised script contract for all build, test, install, and validation scripts.

All scripts under `Scripts/` and all `.swift-agent` command runners MUST conform to the following contract.

### Execution Contract

Every script MUST:
- accept the repository root as the first argument
- operate relative to that root (no implicit working directory assumptions)
- fail fast on error (`set -euo pipefail` for bash scripts)
- emit clear, structured log output

### Run Structure

Every script execution MUST:
- generate a unique run identifier
- use the format: `YYYYMMDD-HHMMSS-<random-suffix>`
- create a run directory under:
  - `build/runs/<run-id>/`
- write all outputs into that run directory

Required substructure:
- `validation/` → validation reports and resolved configs
- `logs/` → raw command output
- `artifacts/` → build outputs when applicable

### Compatibility Mirrors

To preserve backwards compatibility with existing tooling, scripts MUST mirror key outputs to:
- `build/validation/`

This includes:
- doctor reports
- resolved configuration files
- summary outputs required by downstream scripts

### Logging Contract

All scripts MUST:
- print the run id at start
- print the run directory path
- print each major step in the form:
  - `==> step_name`
- print explicit PASS/WARN/FAIL outcomes where applicable

### Path Handling

Scripts MUST:
- use repo-relative paths for all file operations
- avoid hardcoded absolute paths
- resolve all paths through a shared helper where available (e.g. `paths.sh`)


### Python Invocation

Where Python is used:
- scripts MUST resolve the interpreter via a shared helper (e.g. `resolve_python_bin`)
- inline Python blocks MUST receive repo-relative paths as arguments
- large Python logic blocks SHOULD be extracted into dedicated helper scripts over time

### Resolver Contract

All build, test, install, and validation scripts MUST use the shared configuration resolver:

- `runtime/python/resolve-config.py`

The resolver is the single source of truth for interpreting:
- `.swift-agent/project-config.yaml`
- `.swift-agent/commands.yaml`

Scripts MUST NOT:
- reimplement configuration parsing logic inline
- duplicate YAML parsing in bash or embedded Python blocks
- infer defaults independently of the resolver

The resolver MUST:
- accept explicit inputs (resolved config path, mode, repo root, and optional selectors)
- output a fully normalised JSON payload
- fail fast on invalid configuration

Supported modes:
- `build`
- `test`

### JSON Contract

The resolver output is a structured JSON document consumed by scripts.

Scripts MUST:
- treat the JSON payload as authoritative
- extract values using shared JSON helper functions
- avoid direct parsing of YAML or raw config files

### Bash JSON Helpers

All scripts MUST use shared helper functions defined in `bootstrap.sh`:

- `json_file_eval`
- `json_string_eval`
- `json_array_length`
- `json_array_item`
- `json_array_item_field`
- `json_object_field`

Scripts MUST NOT:
- define ad hoc JSON parsing helpers locally
- embed repeated Python snippets for JSON access

### Separation of Concerns

The system is intentionally split as follows:

- Python resolver:
  - configuration parsing
  - validation
  - normalisation

- Bash scripts:
  - orchestration
  - command execution
  - logging and artifact management

This separation MUST be preserved. Configuration logic belongs in the resolver, not in shell scripts.

### Failure Semantics (Resolver)

If resolver execution fails:
- the calling script MUST exit immediately
- the error MUST be surfaced to the user
- no fallback or partial execution is permitted

If required fields are missing from the JSON payload:
- scripts MUST treat this as a fatal error
- scripts MUST NOT attempt to guess defaults

### Command Consistency

All `.swift-agent/commands.yaml` runners MUST:
- reference scripts that comply with this contract
- not duplicate logic already implemented in shared scripts
- pass repo root and required parameters explicitly

### Failure Semantics

Scripts MUST:
- exit non-zero on failure
- never silently ignore missing inputs, configuration, or required artifacts
- surface repository gaps (e.g. missing tests, missing tools) as explicit failures or warnings

### Current Intent

This contract ensures:
- reproducible runs
- auditable outputs
- consistent structure across all build and validation flows
- clean integration with doctor and gate checks

---

## 8. Test Execution Rules

Default:
xcodebuild test -scheme SpeedDemon -project SpeedDemon.xcodeproj

---

## 9. Test Creation and Maintenance (MANDATORY)

- Tests must be created for all new logic
- Tests must be updated when logic changes
- No untested code permitted

---

## 10. Widget and Live Activity Rules

The repository contains:
- WidgetKit extensions
- ActivityKit Live Activities

Agents MUST:
- preserve extension-safe APIs
- preserve shared model compatibility between app and widget targets
- avoid introducing unsupported framework dependencies into widget targets
- ensure widget and Live Activity targets remain buildable independently
- maintain test coverage for shared activity attribute models

---

## 11. Localisation Rules (MANDATORY)

Resources/Localisation/

All user-facing text must be localised.

Includes:
- UI labels
- buttons
- alerts
- error messages
- debug-visible messages
- empty states

Agents MUST NOT:
- hardcode user-facing strings in Swift files

---

## 12. Install Rules

Current repository state:
- no macOS install workflow is currently defined
- install validation is not yet supported

Doctor and gates MUST report install support honestly.

---

## 13. Configuration Rules

- AppConfig
- UserSettings
- ConfigurationProvider

No hardcoding of system config.
Global constants MUST be centralised
User-adjustable values MUST be exposed via settings

---

## 14. Constants and Magic Values

No magic numbers. Use named constants.

---

## 15. Repo-Specific Overrides

Document deviations from global rules.

---

## 16. Completion Criteria

- Build succeeds
- Tests pass
- Artifacts written
- No rule violations
