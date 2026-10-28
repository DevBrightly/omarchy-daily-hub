# Changelog

All notable changes to Daily Hub will be documented in this file.

The project follows [Semantic Versioning](https://semver.org/), and this file
uses the structure described by [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added

- Big 3 priorities with a three-item limit
- separate Today and Later task lists
- task descriptions, editing, reordering, search, and filtering
- movement between Today and Later
- visible carry-over counts
- quick-add shortcuts for Today and Later
- synchronized task and timer state across workspace bar instances

### Changed

- upgraded local state to schema version 2 with automatic migration
- daily progress now excludes Later tasks
- Later tasks persist across days without increasing their carry count

### Developer experience

- added dependency-free model and manifest tests
- added GitHub Actions checks for pushes and pull requests
