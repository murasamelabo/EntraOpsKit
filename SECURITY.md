# Security Policy

## Supported Version

The latest release is supported. Source and release artifacts are publicly inspectable; live tenant
use and generated reports remain the operator's controlled responsibility.

## Security Boundary

EntraOpsKit 0.1.6 is read-only in its built-in live Graph behavior. Its live collector calls only
Microsoft Graph GET endpoints for applications and service principals, requests Application.Read.All,
rejects pagination outside the expected Global Microsoft Graph host and resource path, ignores
`agentIdentityBlueprint` and `agentIdentityBlueprintPrincipal` placeholder objects returned by those
list endpoints, and never emits credential secret or certificate values.

The optional `Request` scriptblock is operator-supplied code intended for testing or controlled
integration. EntraOpsKit validates the URI and GET method passed to it, but cannot prevent unrelated
side effects implemented inside caller-provided code. Use only trusted callbacks.

The report still contains tenant identifiers and operational metadata. Keep reports in approved
storage, restrict access, and remove them according to your retention policy.

## Reporting A Vulnerability

Use GitHub private vulnerability reporting for this public repository. Do not include tenant
identifiers, tokens, credential values, exported reports, or other sensitive data in a public issue.

## Explicit Non-Goals

- credential creation, rotation, or deletion;
- role assignment or permission consent;
- tenant configuration changes;
- token collection or persistence;
- arbitrary Microsoft Graph endpoints or HTTP hosts.