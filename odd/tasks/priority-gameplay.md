# Priority gameplay changes

## Objective and authorized scope

Implement only the two equally high-priority changes approved on 2026-10-18:
1. Always-active hand and a physical broom available from the first day.
2. Existing five-second closing phase becomes dimmed, frozen and coin-only.

The roadmap is `docs/plan-cambios-agarre-escoba.md`, published in commit `200cd0d5060bfbf75d66c34770d21654189c8a2a`.

## Constraints

- Do not implement V progression changes, multi-coin hand upgrades, results button changes, tree redesign or sensory effects.
- Preserve save compatibility, purchased capabilities, banked income and the existing total day duration.
- Preserve historical delivered facts in the roadmap; mark new outcomes only after checks.
- Code and new code comments default to English; existing Spanish documentation remains Spanish.
- The user authorized publishing code and running the APK pipeline, but browser access to github.com was rejected by the origin gate. Publication/pipeline/APK remain pending; do not bypass with gh or another remote method. Delegate performs no commits or remote operations.
- RDD is off, decided globally; do not start reviews or change the switch.

## Testing mode and runner

Task-level TDD is enabled by the user's 2026-10-18 response authorizing compatible SDK setup and test-first implementation. This does not assert repository-wide strict configuration. Runner: `/private/tmp/priority-flutter-3.35.7/flutter/bin/flutter test --no-pub`.

Installed global Flutter was verified as 3.32.0 / Dart 3.8.0. Official stable 3.47.7 was checksum/version verified, but lock enforcement rejected six SDK-pinned transitive changes. CI pins Flutter 3.35.7; its matching official macOS arm64 release (Dart 3.9.2) is installed separately and checksum/version verified. Lock-enforced dependency setup succeeded; baseline was 51 passing tests. Global SDK and dependency versions remain unchanged.

## Tasks

- [x] PG-01: Initialize a persistent broom near the upper-right corner; pick up and release it as a physical item while retaining direct ball/coin hand input. Remove gameplay mode switching without implementing V progression redesign. Verify placement, hit testing, release, ball/broom interactions, saves and older save defaults.
- [x] PG-02: At the existing closing boundary cancel active object gestures safely, freeze balls/broom and non-coin simulation, allow only coin collection, dim everything except coins, and show the existing result popup only after the five seconds. Verify exact boundary/timeout, no captures or duplicate income, and closing restore.
- [x] PG-03: Run applicable focused/full tests, analyzer and formatting; inspect visual contrast if a runnable target is available. Update the roadmap and this file with observed outcomes, limitations and verification evidence.

- [x] PG-04: Publish the verified code and final documentation and generate a test APK, recording the exact source commit and artifact. The user renewed publication authorization and requested a test APK. The local debug build satisfies the current APK request; GitHub Actions was not run because GitHub CLI has no authenticated session.

## Acceptance criteria

Both important behaviors work without granting other pending roadmap features. New days retain the original production/closing durations and existing result navigation. Existing saves retain progress; no active gesture is resurrected. Tests cover new behavior and regressions. Skipped or blocked checks remain explicit.

## Progress and next step

- PG-01 implemented: independent broom pose and grip, always-available hand, no selector; parked geometry remains physical. Saved pose/angle are optional validated additions; old saves receive a safe default; gestures never reload. Purchased V remains usable without changing catalog prices/prerequisites or granting unowned V.
- PG-02 implemented: production boundary cancels grip without throw; explicit coin-only state freezes balls, parked/held broom, robot, generation and captures. Existing landing, tap, sweep and magnet collection capabilities remain available. Board overlay renders before coins; the non-coin HUD is also dimmed with pause still accessible. Existing total duration, banking and results navigation are unchanged.
- Observed TDD: baseline 51 pass (`/private/tmp/priority-baseline.log`); first new test run had four behavioral failures and one pass (`/private/tmp/priority-red.log`), followed by five pass. Expanded tests exposed a coin-only spawn guard failure (`/private/tmp/priority-second-red.log`), then nine pass. Pixel rendering regression extended focused suite to ten pass. HUD regression was observed RED (`/private/tmp/priority-hud-red.log`) then GREEN.
- Four original broom collision fixtures now position the physical item before grabbing it, rather than relying on touch spawning a selected tool. The selector widget regression now exercises real physical V pickup and return to ball-hand input.
- Independent verification found that the purchased magnet stayed at pointer-down during closing: coin-only update returned before normal pointer tracking. Added observed RED (expected collected 2, actual 0; `/private/tmp/priority-magnet-red.log`), then updated only the closing collection cursor in `drag`. GREEN: 11 focused tests (`/private/tmp/priority-magnet-green.log`), with balls/broom frozen and tap/sweep rules unchanged.
- Final source checks after magnet correction: 63 total tests pass (`/private/tmp/priority-final-tests.log`), analyzer reports no issues, check-only format is clean, web build succeeds (`/private/tmp/priority-build-web.log`), and `git diff --check` is clean. Runner/tool prefix is `/private/tmp/priority-flutter-3.35.7/flutter/bin/`.
- PG-03 complete: roadmap current checkboxes and local evidence updated without changing historical delivery records or claiming publication. Automated rendered pixels verify coin contrast; no browser/device gameplay claim. Android physical validation and user feel/acceptance remain pending. Parent spot check: all 11 priority tests pass after correction; an initial unmatched test-name filter ran no tests and was replaced by the complete focused file. Next: authorized code/document publication and APK pipeline remain blocked by GitHub browser origin rejection. No pipeline executed, no APK generated, no alternate remote channel used; source remains uncommitted.
- Engram mirror `odd/priority-gameplay/tasks` remains pending: project-context writes/reviews fail with `unknown_project` / backing-context errors. Preserve this local document as recovery truth.

## Rollback boundaries

Current delivery follow-up, 2026-10-18: `f7bcdef7b80b917102e78545b9729513e927a1e7` was successfully pushed to `origin/main` using the Git authentication explicitly authorized by the user. GitHub CLI has no authenticated session, so workflow dispatch did not run. Flutter 3.35.7 `build apk --debug --no-pub` completed successfully in 235.1 seconds using the local Android SDK. Artifact: `build/app/outputs/flutter-apk/app-debug.apk` (140 MiB); SHA-256: `cd006dc4316a21c77d0d6deb6a4bf07812b79d54b6a9a0f97930cfa71ccb2b88`. Android build-tools 35.0.0 `apksigner verify --verbose` passed with one signer and APK Signature Scheme v2. Required NDK 27.0.12077973, build-tools 35 and platform 36 were installed by the build; no repository source or dependency versions changed. Android device installation, manual gameplay and performance checks remain pending. Engram tools remain unavailable; the mirror is pending. Earlier blocked-publication notes below are historical. Delivery policy: RDD disabled/unmanaged.

Publication follow-up, 2026-10-18: user requested committing and pushing all pending changes on `main`. Rechecked with Flutter 3.35.7: all 63 tests pass, analyzer reports no issues, check-only formatting reports 26 files unchanged, and `git diff --check` passes. The initial sandboxed test attempt could not open local sockets; the authorized elevated run passed. Browser origin access to github.com was again denied by automatic approval review for missing explicit session authorization. No push or pipeline was attempted through another channel. PG-04 remains incomplete; Engram tools are unavailable and the mirror remains pending. Next step: explicit authorization for the GitHub session/channel, then push the prepared local commit.

PG-01 is the physical-broom/input/save unit; PG-02 is closing-state/simulation/rendering. Both are packaged together with their regression tests and documentation as one gameplay delivery. Reverting that delivery removes both behaviors without affecting earlier commits. Runtime validation: automated Flutter widget and rendered-pixel tests passed; manual browser/device gameplay remains pending.
