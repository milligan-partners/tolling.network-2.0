# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it using [GitHub's private vulnerability reporting](https://github.com/milligan-partners/tolling.network-2.0/security/advisories/new).

**Do not open a public issue for security vulnerabilities.**

We will acknowledge receipt within 48 hours and aim to provide a fix or mitigation plan within 14 days, depending on severity.

## What to Include

When reporting, please include:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

## Supported Versions

| Version | Supported |
|---------|-----------|
| main branch | Yes |
| All others | No |

## Security Requirements

This project handles toll interoperability data for government transportation agencies. All contributions must follow the security requirements in [CONTRIBUTING.md](CONTRIBUTING.md#security-requirements).

Key requirements:

- No credentials, API keys, or PII in commits
- TLS required for all network communication
- Input validation on all chaincode functions
- Real encryption for sensitive ledger data (not Base64 encoding)
