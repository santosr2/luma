# Security Policy

## Supported Versions

Currently supported versions of Luma:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please report it responsibly.

### How to Report

**DO NOT** open a public GitHub issue for security vulnerabilities.

Instead, please email security concerns to: **security@luma-project.org** (or your contact email)

Include in your report:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response Timeline

- **Initial Response:** Within 48 hours
- **Status Update:** Within 7 days
- **Fix Timeline:** Depends on severity
  - Critical: 1-7 days
  - High: 7-30 days
  - Medium: 30-90 days
  - Low: Best effort

### Disclosure Policy

- Reporter will be credited (unless anonymity is requested)
- Security advisories will be published after fixes are released
- CVE will be requested for significant vulnerabilities

## Security Best Practices

When using Luma:

1. **Template Sources:** Only load templates from trusted sources
2. **User Input:** Never pass unsanitized user input directly to templates
3. **Sandboxing:** Use Luma's sandbox mode for untrusted templates
4. **Updates:** Keep Luma updated to the latest version
5. **Autoescape:** Enable autoescape for HTML contexts

Thank you for helping keep Luma secure!

