# Security Policy

## Supported Version

The latest release is supported. Source and release artifacts are publicly inspectable; live tenant
use and generated reports remain the operator's controlled responsibility.

## Security Boundary

EntraOpsKit 0.1.4 is read-only. Its live collector calls only Microsoft Graph GET endpoints for
applications and service principals, requests Application.Read.All, rejects pagination outside the
expected Global Microsoft Graph host and resource path, and never emits credential secret or
certificate values.

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