# Changelog

## v0.1.2 - 2026-07-14

- Add explicit CSV export regression coverage to the Pester suite.
- Keep the read-only Microsoft Graph boundary and no-secret output behavior unchanged.
- Preserve the existing GET-only application and service-principal inventory flow.

## v0.1.1 - 2026-07-14

- Correct public repository and private vulnerability-reporting language.
- Replace an invalid multi-path PSScriptAnalyzer example with executable commands.
- Align CI PowerShell indentation and module metadata with version 0.1.1.
- Keep the GET-only Microsoft Graph behavior and `Application.Read.All` boundary unchanged.

## v0.1.0 - 2026-07-14

- Add GET-only application and service-principal credential inventory.
- Add deterministic expired, critical, warning, healthy, and unknown classification.
- Add JSON and CSV reporting without credential values.
- Add Graph pagination with strict HTTPS host and resource-path validation.
- Add an offline test runner, Pester coverage, PSScriptAnalyzer CI, and pinned checkout action.
- Document least privilege, report handling, release invariants, and candidate follow-up tools.