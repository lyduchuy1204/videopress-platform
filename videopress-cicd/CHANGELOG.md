# Changelog

Mọi thay đổi đáng chú ý của repo này đều được ghi tại đây.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Scaffold cấu trúc Jenkins Shared Library: `vars/`, `src/com/videopress/{aws,notify,terraform}`, `pipelines/`, `docs/`.
- 5 pipeline DSL global function: `pythonLambdaPipeline`, `terraformPlanPipeline`, `terraformDeployPipeline`, `terraformRollbackPipeline`, `smokeTestPipeline`.
- `PlanReviewBot.analyze()` phát hiện DynamoDB schema change từ `plan.json`.
- 6 Jenkinsfile sample trong `pipelines/`.
- 3 doc: `pipeline-design.md`, `secrets-management.md`, `on-call-runbook.md`.
- Spock spec skeleton + fixture `plan-with-dynamodb-destroy.json`.
- Build config: Gradle + CodeNarc + JaCoCo (coverage gate ≥ 80%).

### Changed
- _none_

### Deprecated
- _none_

### Removed
- _none_

### Fixed
- _none_

### Security
- _none_

---

## [0.1.0] - 2025-01-XX

### Added
- Initial scaffolding (commit này).

[Unreleased]: https://github.com/videopress/videopress-cicd/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/videopress/videopress-cicd/releases/tag/v0.1.0
