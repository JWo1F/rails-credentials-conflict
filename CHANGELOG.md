# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-04-13

### Added

- Automatic credentials conflict resolution via a custom git merge driver
- `base` command to select the base version from git stages
- Auto-merge of non-conflicting changes in different sections
- Conflict markers enriched with branch names and commit SHAs
- Use of `git merge-file` to produce proper conflict markers

### Changed

- Refactored resolver into focused, single-responsibility classes
- Enhanced documentation and error handling across conflict resolution
- Improved gem summary and description
- Lowered Ruby version requirement

### Fixed

- Read resolved content from disk after the editor saves
- Task argument syntax for the environment parameter

## [0.1.0] - 2025-01-01

### Added

- Initial release
- Rake tasks for resolving encrypted credentials conflicts: `resolve`, `yours`, `theirs`, `base`
- Three-way merge with conflict markers and editor-based resolution
- Support for environment-specific credentials
- YAML validation of resolved content
- Automatic staging of resolved files
