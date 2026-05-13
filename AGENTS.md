# AGENTS.md

## Purpose

This repository contains the SpeedDemon native Apple app.

SpeedDemon is also used as the second canary project for the shared Swift scripting system. The repository must prove that the build, test, install, doctor, and gate scripts are reusable across projects and are not coupled to HomesteadAssetRegister-specific assumptions.

The application code should remain clean, local-first where practical, and aligned with Apple-platform conventions. The scripting layer must remain driven by repository configuration, not hardcoded project logic.

---

## Engineering Rules

- Preserve SpeedDemon-specific product behavior and do not reshape the app merely to suit the scripting harness.
- Keep project-specific build, test, install, and scheme values in `.swift-agent/project-config.yaml`.
- Keep command entry points in `.swift-agent/commands.yaml`.
- Do not hardcode SpeedDemon values into shared scripts.
- Prefer Apple frameworks before introducing external dependencies.
- Keep app configuration centralized through the standard configuration pattern:
  - `AppConfig`
  - `UserSettings`
  - `ConfigurationProvider`
- Avoid unexplained literals and magic values.
- Keep user-facing strings centralized or ready for localization.
- Surface missing tests, missing schemes, missing tooling, or incomplete project structure honestly through doctor/gate output.
- Do not resolve lint errors by suppressing rules. Fix the underlying code/issues directly unless the user explicitly approves a narrowly scoped exception.
- All code changes MUST conform to this repository’s SwiftFormat and SwiftLint rules.

---

## Canary Role

SpeedDemon is a portability canary for the shared Swift Agent scripting system.

The repository should validate that:

- scripts accept the repository root as their first argument
- scripts operate relative to that root
- project identity comes from `.swift-agent/project-config.yaml`
- commands come from `.swift-agent/commands.yaml`
- outputs are written under `build/runs/<run-id>/`
- compatibility mirrors are written under `build/validation/`, `build/tests/`, and `build/artifacts/` where required
- no shared script assumes HomesteadAssetRegister naming, schemes, bundle identifiers, paths, or targets

If SpeedDemon exposes a genuine portability bug, fix the shared script carefully and prove that the fix remains generic.

---

## Code Organization

Expected repository structure:

- `.swift-agent/`: project-specific Swift Agent configuration.
- `SpeedDemon.xcodeproj`: canonical checked-in Xcode project.
- `Sources/`: application source code where applicable.
- `Tests/`: test source code where applicable.
- `Scripts/`: repository-specific helper scripts where required.
- `runtime/`: shared scripting runtime and helper libraries where vendored into this repo.
- `docs/`: project documentation where present.
- `build/`: generated outputs only; not a source-of-truth location.

Agents MUST inspect the actual repository before assuming paths exist.

If current structure differs from this layout, report the gap rather than inventing files, targets, or schemes.

---

## Xcode Project Ownership

The checked-in Xcode project is the source of truth for Apple app build ownership.

Agents MUST:

- preserve the checked-in Xcode project
- preserve shared schemes under `SpeedDemon.xcodeproj/xcshareddata/xcschemes` where they exist
- use repository scripts for build and test verification
- treat `.swift-agent/project-config.yaml` as the machine-readable source for project-specific build/test/install settings

Agents MUST NOT:

- regenerate or replace the Xcode project
- rely on `xcuserdata` as the source of truth
- move canonical Xcode version ownership into external config files
- fabricate schemes, targets, or destinations that are not present

---

## Versioning Rules

Version source of truth:

- `MARKETING_VERSION` -> Xcode project
- `CURRENT_PROJECT_VERSION` -> Xcode project

Rules:

- major/minor versions are manually incremented only
- build number handling must follow the shared scripting contract
- canonical version values must not be stored in external config files

If the repository does not yet contain a working build-number increment path, doctor/gate checks must surface that honestly.

---

## Build and Test Rules

Default validation should use the smallest reliable build path available for SpeedDemon, normally an iOS Simulator build if the project supports it.

Build and test commands are defined through:

- `.swift-agent/project-config.yaml`
- `.swift-agent/commands.yaml`

Agents MUST:

- use `doctor.sh`, `run-build.sh`, `run-tests.sh`, and `run-gates.sh`
- select only real configured build keys
- report missing or incomplete test infrastructure as blocked, not passed
- keep build/test orchestration inside repository scripts

Agents MUST NOT:

- call `xcodebuild` directly
- create one-off shell build commands
- infer missing defaults outside the resolver
- claim test success when no test target exists

---

## Data, State, and Persistence Requirements

Because SpeedDemon is partially developed, agents must inspect the actual implementation before changing persistence, state management, or app lifecycle behavior.

When data or state logic changes, agents must verify as applicable:

- app launch still reaches the expected root view
- persisted data remains readable after changes
- sample/seed data paths still work where present
- user settings remain backward compatible
- app state restoration or local cache behavior is not broken
- migrations are explicit and reviewable where required

Do not introduce network, sync, telemetry, or cloud behavior unless explicitly requested.

For trip runtime behavior:

- Only one trip may be active (`isRunning == true`) at a time.
- Starting a trip while another is active must first pause/close the currently active trip session, then start the selected trip.
- Live Activity content must stay aligned with trip state transitions (start/pause/resume/reset), including duration and average speed fields when present.

---

## User Interface Rules

Agents MUST:

- preserve existing navigation structure unless the task requires changing it
- keep SwiftUI views small enough to review
- move reusable UI into shared components when reuse is real, not speculative
- avoid scattering user-facing strings
- avoid opportunistic redesigns
- keep accessibility in mind for labels, buttons, and dynamic text

Agents MUST NOT:

- restyle the app wholesale during unrelated changes
- introduce placeholder UI without marking it clearly
- remove incomplete screens merely because they do not yet pass polish standards

---

## Review Checklist

Before proposing or applying changes, check the relevant items:

- Project-specific values remain in `.swift-agent/project-config.yaml`.
- Command entry points remain in `.swift-agent/commands.yaml`.
- Shared scripts remain project-agnostic.
- Xcode schemes referenced by config actually exist.
- Build keys used by commands actually exist.
- Any changed Swift files still follow the repository style.
- New logic has tests, or the missing test infrastructure is reported as a blocker.
- Generated outputs remain under `build/`.
- No DerivedData path is treated as a retained artifact location.
- No HomesteadAssetRegister names, paths, schemes, or bundle identifiers remain in SpeedDemon config or docs unless used as explanatory examples.

---

## Commit Strategy

- Keep commits focused by concern:
  - scripting config
  - project rules
  - app source changes
  - tests
  - docs
- Include build or validation notes in commit messages when relevant.
- Do not mix broad cleanup with functional changes.
- Do not commit generated `build/` outputs unless explicitly requested.

## Swift Header Version Rule

- Every Swift file header `Version` must use `x.y.z`.
- `x.y` is the marketing version.
- `z` is the build number.
- Header `Version` values MUST match the current version produced by `increment_build_number.sh` (project source of truth), not an inferred/manual patch increment.
- When any Swift file is changed, update both header fields in that file:
  - `Version`
  - `Last Modified`
- When any Swift file is changed, update the `Changes` block with a change line that matches the `.swiftlint.yml` header pattern:
  - `Craig Little <dd/MM/yyyy> <brief description>`
- If a related `Craig Little` entry already exists for today in that file’s `Changes` block, update that existing line instead of adding a duplicate line.

---

## Codex Execution Policy

This repository uses a controlled integration model for Codex or similar agents. The goal is to reduce iteration loops while preserving strict human review control.

### Execution Modes

General rule:

- In all modes, the agent MAY inspect repository source files, configuration files, and logs as needed unless explicitly forbidden.
- “Run commands” means executing shell or repository commands.
- Read-only inspection commands are allowed only where explicitly permitted below.

Agents MUST operate in one of the following modes:

#### `patch_only`

- The agent MAY read and inspect repository source files as needed.
- The agent MAY modify repository source files.
- The agent MAY run read-only inspection commands for file discovery and file contents only.
- The agent MUST NOT run build, test, install, lint, format, git, network, package-manager, or any other mutating or verification commands.
- Output should consist of the proposed/applied code changes only.

#### `patch_and_verify_once`

- The agent MAY read and inspect repository source files as needed.
- The agent MAY modify repository source files.
- The agent MAY run read-only inspection commands for file discovery and file contents.
- After making changes, the agent MAY run approved repository scripts ONCE for verification.
- The agent MUST NOT make any further edits after verification.
- The agent MUST report the verification results.

#### `diagnose_only`

- The agent MAY read and inspect repository source files, logs, and outputs.
- The agent MAY run read-only inspection commands for file discovery and file contents.
- The agent MUST NOT modify code or other repository files.
- The agent MUST NOT run build, test, install, lint, format, git, network, package-manager, or other mutating commands.
- The agent MUST provide analysis only.

---

## Approved Commands

Agents MUST use repository scripts for all validation. Direct tool invocation is prohibited.

Approved commands:

```bash
doctor.sh .
run-build.sh . <build-key>
run-tests.sh . [runner flags]
run-gates.sh . <build-key>
run-install.sh . <install-key>
snapshot-validation.sh .
```

Use only build, test, and install keys that are defined for SpeedDemon.

---

## Prohibited Actions

Agents MUST NOT:

- call `xcodebuild` directly
- implement their own build or test orchestration
- perform multiple edit/build loops
- retry commands automatically
- modify files outside the requested scope
- perform opportunistic refactors or cleanup
- revert user changes unless explicitly instructed
- hide missing test infrastructure
- copy HomesteadAssetRegister-specific configuration into SpeedDemon without replacing it with real SpeedDemon values

---

## Verification Rules

When in `patch_and_verify_once` mode:

- each approved command may be run at most once
- no additional commands may be introduced
- no second-pass edits are allowed
- results MUST be reported
- execution MUST stop after reporting

If verification fails, report the failure and stop. Do not repair and retry unless the user explicitly starts a new instruction cycle.

---

## Success Criteria

A change is considered valid when:

- repository scripts exit successfully, or blockers are explicitly reported
- no contract checks fail silently
- generated outputs are written to the expected `build/` locations
- SpeedDemon-specific config remains separate from shared script logic
- no additional repair attempts are made after verification

Agents MUST report results and stop for human review.

---

## Separation of Responsibility

- Repository scripts define all build, test, install, and validation behavior.
- `.swift-agent/project-config.yaml` defines SpeedDemon project-specific build/test/install facts.
- `.swift-agent/commands.yaml` defines command entry points.
- Agents operate as patch authors and controlled verifiers only.
- Shared scripts must stay generic across canary projects.

---

## Canonical Doctrine

> Patch once. Verify once. Report once. Stop.

---

## Verification Profiles

These profiles are allowed only when the referenced build/test keys exist in SpeedDemon configuration.

### `ios_fast`

```bash
doctor.sh .
run-build.sh . ios_simulator
run-tests.sh .
```

### `macos_fast`

```bash
doctor.sh .
run-build.sh . macos
run-tests.sh . --runners=macos
```

### `canary_gates`

```bash
doctor.sh .
run-gates.sh . ios_simulator
```

If a profile references a missing key or target, report it as a configuration gap rather than inventing a replacement.
