# Versioning policy — videopress-cicd

Repo này dùng **Semantic Versioning** ([semver.org](https://semver.org/)) cho mọi tag release.

## Quy tắc bump

| Loại thay đổi | Bump | Ví dụ |
|---|---|---|
| **Breaking change** ở DSL signature (xoá tham số, đổi kiểu trả về, đổi tên function) | `MAJOR` | `v1.x.y` → `v2.0.0` |
| Thêm tham số optional, thêm function mới, thêm stage mới (default off) | `MINOR` | `v1.2.x` → `v1.3.0` |
| Bug fix, refactor nội bộ, cải tiến perf — KHÔNG đổi API | `PATCH` | `v1.2.3` → `v1.2.4` |

## Tag convention

- Format: `vMAJOR.MINOR.PATCH` (ví dụ `v1.2.0`, `v0.5.3`).
- KHÔNG dùng prefix khác (`release-`, `r-`, ...).
- Pre-release: `v1.2.0-rc.1`, `v1.2.0-beta.1`.

## Cách bump tag

```bash
# 1. Sync main
git checkout main
git pull origin main

# 2. Update CHANGELOG.md — chuyển section [Unreleased] thành [vX.Y.Z]
# 3. Commit changelog
git add CHANGELOG.md
git commit -m "chore(release): v1.2.0"

# 4. Tag annotated (KHÔNG dùng lightweight tag)
git tag -a v1.2.0 -m "Release v1.2.0 — add prod cooldown gate"

# 5. Push
git push origin main
git push origin v1.2.0
```

## Pin version ở consumer

```groovy
@Library('videopress-cicd@v1.2.0') _   // ✅ pin tag — ổn định cho prod
@Library('videopress-cicd@main') _      // ⚠️ chỉ dev — có thể break bất kỳ lúc nào
```

## Hỗ trợ version cũ

- **MAJOR hiện tại**: full support — bug fix + security patch.
- **MAJOR trước đó (N-1)**: chỉ security patch trong **6 tháng**.
- **MAJOR cũ hơn**: không support, khuyến nghị migrate.
