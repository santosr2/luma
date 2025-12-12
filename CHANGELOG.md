# Changelog

All notable changes to Luma will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- {% with %} directive for scoped variables
- {% filter %} blocks for content filtering
- namespace() function for mutable variables in loops
- {% include %} context modifiers (with/without context, ignore missing)
- {% do %} statement for side effects
- Complete Jinja2 feature parity (100%)
- Comprehensive test suite (26 spec files)
- GitHub Actions CI/CD workflows
- Pre-commit hooks configuration
- Luacheck code quality checks
- Security policy and contributing guidelines

### Changed
- Enhanced template inheritance with super() function
- Improved whitespace control with context-aware inline mode
- Extended filter system with named arguments

### Fixed
- Various parser edge cases
- Whitespace handling in nested blocks

## [1.0.0] - TBD

### Added
- Initial release with 100% Jinja2 compatibility
- Native Luma syntax (@directives, $variables)
- Smart indentation preservation
- Template inheritance system
- Macro system with caller support
- 40+ built-in filters
- Comprehensive test expressions
- Autoescape for security
- Migration tool from Jinja2

[Unreleased]: https://github.com/santosr2/luma/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/santosr2/luma/releases/tag/v1.0.0
