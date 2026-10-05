
# PyGDS-CPython Differences List

This file records the behavioral differences and missing features between PyGDS and CPython, grouped by cause into three families: language-core alignment gaps (Issue), intentional alternative models (Design), and host-platform constraints (Platform), covering both open and resolved entries, for version planning and handover use. This file is not a migration of the GitHub repository's Issues page, but it may reference relevant links from the Issues page. In this file the word Issue specifically denotes the language-core alignment-gap category and has nothing to do with GitHub Issues. This file follows the [Code and Documentation Standards](./standards.md#code-and-documentation-standards)

The three families are classified by the criterion of "who decides the difference":

- **Issue (I IDs, language-core layer)**: alignment gaps in the language core, such as the data model, evaluation order, builtin-type behavior on pure values, and the exception class hierarchy. Alignment requirement: must match CPython — this is the part users can safely rely on, and dual-end differential testing is its regression safety net. Graded by `Priority` 0 / 1 / 2:
  - **I0**: silently produces wrong results (wrong values/output without raising)
  - **I1**: raises an explicit error or misses a feature (predictable, never silently wrong)
  - **I2**: edge differences in behavior (different error types/messages, but both sides raise or both succeed)
- **Design (D IDs, design layer)**: intentional alternative models and established non-alignment (own PRNG, stable identity hashes, the step-limit safety valve). Alignment requirement: intentional, documented, explicit errors over silent wrong values where possible; matching CPython is not pursued
- **Platform (P IDs, platform layer)**: differences decided by the host platform, such as file paths, encodings, libm rounding, precision boundaries, and engine hard limits. Alignment requirement: document the differences honestly per host platform — CPython itself varies across platforms too; entries should be re-checked for removal after host upgrades

The three families count their IDs independently, composed of `<category letter>[<sub-category><->]<sequence>`, as follows:

- Issue: `I<Priority>-<sequence>`, e.g. `I0-1` denotes the first Priority-0 issue within Issue (P0 here specifically means Priority 0, not Platform 0)
- Design: `D<sequence>`, e.g. `D1` denotes the first entry within Design
- Platform: `P<sequence>`, e.g. `P1` denotes the first entry within Platform

Even after an entry is resolved, its sequence number is never recycled. When an Issue entry moves into Design / Platform, its original ID is retired and must not be taken by new entries

## Entry Summary Table

Entries are summarized below; the Status column is filled per family:

- Issue: Unfixed / Fixed / Deferred (fix postponed)
- Design: Intentional design / Aligned
- Platform: Host constraint / Lifted

The ID column should link to the corresponding entry section, and dates should follow the `YYYY-MM-DD` format

### Issue Summary Table

| ID | Status | Date | Version | Brief Description |
| :--- | :--- | :--- | :--- | :--- |
| - | - | - | - | - |

### Design Summary Table

| ID | Status | Date | Version | Brief Description |
| :--- | :--- | :--- | :--- | :--- |
| - | - | - | - | - |

### Platform Summary Table

| ID | Status | Date | Version | Brief Description |
| :--- | :--- | :--- | :--- | :--- |
| - | - | - | - | - |

## Priority 0 Issues (Issue-Priority 0)

## Priority 1 Issues (Issue-Priority 1)

## Priority 2 Issues (Issue-Priority 2)

## Design-Layer Differences (Design)

## Platform-Layer Differences (Platform)
