# Security Policy

## Supported Version

The latest release is supported. This project is currently private and intended for controlled
operator use.

## Security Boundary

EntraOpsKit 0.1.0 is read-only. Its live collector calls only Microsoft Graph `GET` endpoints for
applications and service principals. It requests `Application.Read.All`, rejects pagination outside
the expected Global Microsoft Graph host and resource path, and never emits credential secret or
certificate values.

The report still contains tenant identifiers and operational metadata. Keep reports in approved
storage, restrict access, and remove them according to your retention policy.

## Reporting A Vulnerability

Use the repository's private GitHub security advisory flow. Do not include tenant identifiers,
tokens, credential values, exported reports, or other sensitive data in a public issue.

## Explicit Non-Goals

- credential creation, rotation, or deletion;
- role assignment or permission consent;
- tenant configuration changes;
- token collection or persistence;
- arbitrary Microsoft Graph endpoints or HTTP hosts.