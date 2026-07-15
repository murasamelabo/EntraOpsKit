# Security Policy

## Supported Version

The latest release is supported. Source and release artifacts are publicly inspectable; live tenant use and generated reports remain the operator's controlled responsibility.

## Security Boundary

EntraOpsKit 0.1.10 is read-only in its built-in live Graph behavior. Its live collector calls only Microsoft Graph GET endpoints for applications and service principals, requires Application.Read.All, rejects pagination outside the expected Global Microsoft Graph host and resource path, rejects non-HTTPS links, non-default ports, user information, fragments, and repeated pagination URIs per resource after canonicalizing equivalent relative and absolute Global Graph forms. It ignores documented agent-identity placeholder objects and never emits credential secret or certificate values.

When the module establishes a connection, it requests Application.Read.All with process-scoped context. An existing operator context can contain broader scopes. Regardless of those scopes, built-in collection remains restricted to the documented GET endpoints. When a requested TenantId is supplied, the active context must identify the same tenant before collection begins.

The optional Request scriptblock is operator-supplied code intended for testing or controlled integration. It bypasses module-managed authentication and context validation. EntraOpsKit validates the URI and GET method passed to it but cannot prevent unrelated side effects in caller-provided code. Use only trusted callbacks.

The report contains tenant identifiers and operational metadata. Keep reports in approved storage, restrict access, and remove them according to policy.

## Reporting A Vulnerability

Use GitHub private vulnerability reporting. Do not include tenant identifiers, tokens, credential values, exported reports, or other sensitive data in a public issue.

## Explicit Non-Goals

- credential creation, rotation, or deletion;
- role assignment or permission consent;
- tenant configuration changes;
- token collection or persistence;
- arbitrary Microsoft Graph endpoints or HTTP hosts;
- national-cloud compatibility in the current Global Graph implementation.