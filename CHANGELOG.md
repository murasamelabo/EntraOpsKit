# Changelog

## v0.1.5 - 2026-07-14

- Ignore `agentIdentityBlueprint` and `agentIdentityBlueprintPrincipal` placeholder objects returned by the Graph list endpoints.
- Refresh release metadata and security wording to match the current read-only GET-only Microsoft Graph boundary.
- Keep the read-only Microsoft Graph boundary and no-secret output behavior unchanged.

## v0.1.4 - 2026-07-14

- Refresh release metadata and security wording to match the current read-only GET-only Microsoft Graph boundary.
- Add a regression test that checks version alignment across the module manifest, README, and SECURITY documentation.
- Keep the read-only Microsoft Graph boundary and no-secret output behavior unchanged.

## v0.1.3 - 2026-07-14

- Add a real Pester regression test for CSV export safety.
- Update version metadata and documentation to match the new release.
- Keep the read-only Microsoft Graph boundary and no-secret output behavior unchanged.

## v0.1.2 - 2026-07-14

- Docs-only release; the CSV export coverage was described but not yet implemented.
- Keep the read-only Microsoft Graph boundary and no-secret output behavior unchanged.
- Preserve the existing GET-only application and service-principal inventory flow.

## v0.1.1 - 2026-07-14

- Correct public repository and private vulnerability-reporting language.
- Replace an invalid multi-path PSScriptAnalyzer example with executable commands.
- Align CI PowerShell indentation and module metadata with version 0.1.1.
- Keep the GET-only Microsoft Graph behavior and Application.Read.All boundary unchanged.

## v0.1.0 - 2026-07-14

- Add GET-only application and service-principal credential inventory.
- Add deterministic expired, critical, warning, healthy, and unknown classification.
- Add JSON and CSV reporting without credential values.
- Add Graph pagination with strict HTTPS host and resource-path validation.
- Add an offline test runner, Pester coverage, PSScriptAnalyzer CI, and pinned checkout action.
- Document least privilege, report handling, release invariants, and candidate follow-up tools.