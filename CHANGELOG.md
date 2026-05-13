# Changelog

All notable changes to SpeedDemon are documented in this file.

## [Unreleased]

### Added
- Settings `About` section now shows app version/build as `x.y.z` and includes a `Report an issue` link to the public support repository.
- Added repository `SECURITY.md` with guidance for reporting vulnerabilities privately and using public issues only for non-sensitive support/bugs.
- Live Activity payload now includes `durationSeconds` and `averageSpeedKmh` so richer status can be rendered across surfaces.

### Changed
- Live Activity title now includes the monitored trip name when available (`Speed Demon - <TripName>`).
- Live Activity main display now presents two metric columns:
  - Left: `Distance`, `Speed`
  - Right: `Duration`, `Avg Speed`
- Refactored Live Activity manager update/start APIs to use a single snapshot payload model to satisfy lint parameter limits.
- Enforced single-active-trip behavior: starting a trip now auto-pauses any other active trip first.

### Fixed
- Resolved split-file access and signature mismatch regressions introduced during recent refactors (Settings helpers, Live Activity call sites).
- Addressed recurring SwiftLint issues around type/file organization and body size by extracting view helpers and simplifying call contracts.
