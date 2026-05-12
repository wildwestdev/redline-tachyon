# SPEC.md

## Purpose

This document defines the architectural, operational, and engineering expectations for the Speed Demon repository.

It exists to:

* provide a stable implementation contract for human and agent contributors
* prevent architectural drift
* preserve deterministic build and validation behaviour
* ensure repository automation remains portable across projects
* define repository-wide engineering doctrine

This file complements:

* `AGENTS.md` → agent execution and behavioural rules
* `PROJECT_RULES.md` → repository-specific overrides and operational truth
* `.swift-agent/project-config.yaml` → machine-readable build/test/install configuration
* `.swift-agent/commands.yaml` → command orchestration definitions

---

# 1. Repository Intent

Speed Demon is a native Apple application repository intended to act as:

* a production-capable Swift application
* a secondary canary repository for the shared Swift Agent scripting framework
* a validation target for reusable build, gate, install, and test orchestration

The repository exists partly to prove that:

* the scripting system is portable
* orchestration logic is not hardcoded to a single application
* repository automation can scale across multiple Apple projects
* project-specific behaviour can be isolated into configuration rather than shell script forks

The repository must remain suitable for:

* local developer workflows
* Codex-assisted development
* deterministic CI/CD execution
* reproducible validation and build auditing

---

# 2. Architectural Principles

## 2.1 Local Repository Ownership

The repository owns:

* its Xcode project
* its schemes
* its build configuration
* its artifact structure
* its validation outputs

Agents MUST NOT:

* regenerate the initial Xcode project
* move canonical configuration into hidden tooling
* introduce opaque external orchestration systems

---

## 2.2 Script System Ownership

The shared scripting system is authoritative for:

* build orchestration
* test orchestration
* install orchestration
* validation and gate execution
* run artifact management
* logging contracts
* resolver execution

The scripts are designed to be:

* portable
* deterministic
* repository-agnostic
* configuration-driven

Project-specific behaviour belongs in:

* `.swift-agent/project-config.yaml`
* `.swift-agent/commands.yaml`
* `PROJECT_RULES.md`

Project-specific behaviour MUST NOT be embedded into shared scripts.

---

## 2.3 Deterministic Execution

All build and validation flows must be reproducible.

Scripts MUST:

* fail fast
* emit structured logs
* produce deterministic outputs
* avoid hidden state
* avoid dependence on shell working directory assumptions

The repository must always support:

* clean execution from a fresh clone
* deterministic script execution
* repeatable validation behaviour

---

# 3. Build and Validation Doctrine

## 3.1 Canonical Build Ownership

The checked-in Xcode project is the canonical Apple build definition.

Canonical ownership includes:

* targets
* schemes
* signing configuration
* build settings
* version values

Version ownership remains inside the Xcode project.

The repository MUST NOT:

* duplicate version values in YAML
* move canonical build settings into shell scripts
* infer schemes dynamically without validation

---

## 3.2 Run Structure

Every script execution must generate:

```text
build/runs/<run-id>/
```

The run directory is the canonical retained execution record.

Required subdirectories:

```text
validation/
logs/
artifacts/
```

Compatibility mirrors may exist under:

```text
build/validation/
build/tests/
```

But these are convenience mirrors only.

The run directory remains authoritative.

---

## 3.3 Logging Contract

Scripts MUST emit:

```text
Run ID: <id>
Run directory: <path>
==> step_name
PASS: step
FAIL: step
WARN: step
```

Logs must remain:

* human-readable
* machine-parseable
* auditable

Silent failures are prohibited.

---

# 4. Configuration System

## 4.1 Resolver Ownership

Configuration parsing belongs exclusively to:

```text
runtime/python/resolve-config.py
```

The resolver is authoritative for:

* project config parsing
* command config parsing
* selector validation
* normalisation
* structured JSON output

Shell scripts MUST NOT:

* parse YAML directly
* duplicate resolver logic
* implement parallel config systems

---

## 4.2 JSON Contract

Resolver outputs are consumed as structured JSON.

Scripts MUST:

* treat JSON as authoritative
* use shared JSON helper functions
* avoid ad hoc parsing patterns

Shared helper functions are expected to remain centralised.

---

# 5. Swift Engineering Standards

## 5.1 File Structure

Swift files should follow this structure:

1. imports
2. type definition
3. stored properties
4. initialisers
5. public methods
6. private methods
7. extensions

One primary type per file.

---

## 5.2 Naming Rules

Use:

* `UpperCamelCase` for types
* `lowerCamelCase` for methods and properties
* verb-based naming for methods
* explicit names over abbreviations

Avoid:

* ambiguous identifiers
* unexplained acronyms
* generic helper names

---

## 5.3 Constants and Configuration

Magic values are prohibited.

System configuration must be centralised.

Expected configuration pattern:

* `AppConfig`
* `UserSettings`
* `ConfigurationProvider`

User-adjustable values belong in settings.

Environment-sensitive values must not be hardcoded.

---

## 5.4 Dependency Management

Prefer Apple frameworks first.

Third-party dependencies require justification.

Avoid:

* unnecessary abstraction layers
* dependency bloat
* framework duplication

---

# 6. Testing Doctrine

## 6.1 Test Philosophy

Tests are mandatory for:

* new logic
* behavioural changes
* bug fixes
* shared utilities
* resolver logic

Tests should prioritise:

* deterministic execution
* small scope
* isolated failures
* fast execution

---

## 6.2 Validation Philosophy

The repository distinguishes between:

* build validation
* test validation
* gate validation
* install validation

Each script has a distinct responsibility.

Scripts must not absorb each other’s roles.

---

## 6.3 Failure Semantics

Failure must be explicit.

The system MUST NOT:

* silently continue
* invent defaults
* suppress resolver errors
* report false success

Repository gaps must be surfaced honestly.

---

# 7. Agent Execution Model

The repository follows a controlled patch-and-verify model.

Core doctrine:

> Patch once. Verify once. Report once. Stop.

Agents are contributors, not autonomous maintainers.

Agents MUST:

* preserve repository contracts
* avoid opportunistic refactors
* avoid uncontrolled iteration loops
* use repository scripts for validation

Agents MUST NOT:

* invoke `xcodebuild` directly
* replace repository orchestration
* fabricate passing validation
* bypass script contracts

---

# 8. Artifact Retention Rules

The repository owns its validation outputs.

Retained artifacts include:

* build summaries
* validation summaries
* resolved configuration snapshots
* test summaries
* gate summaries
* install logs

DerivedData is not considered a canonical retained artifact location.

---

# 9. Repository Portability Goals

Speed Demon acts as a portability canary.

Changes to the scripting framework should be validated against:

* HomesteadAssetRegister
* Speed Demon

This ensures:

* shared script portability
* reduced hidden coupling
* reduced repository-specific assumptions
* stronger automation resilience

If a script change works for one repository but breaks another, the system should treat this as evidence of portability drift.

---

# 10. Completion Criteria

A task is considered complete only when:

* requested changes are implemented
* repository contracts remain intact
* validation outputs are generated correctly
* no hidden failures exist
* script contracts remain compliant
* portability is preserved
* no unnecessary architectural drift is introduced

Success requires:

* honest reporting
* deterministic outputs
* reproducible execution
* preservation of repository doctrine
