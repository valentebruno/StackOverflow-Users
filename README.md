# Stack Overflow Users

An iOS app that fetches and displays the top Stack Overflow users, with local follow state, offline fallback, and a testable UIKit architecture.

Built as a take-home exercise, focused on clarity, correctness, and maintainability within a reasonable scope.

## Requirements

- Xcode 15 or newer
- iOS 16.0 deployment target
- Swift 5.9+
- UIKit only
- No third-party dependencies

## Running the App

1. Open `StackOverflowUsers.xcodeproj`.
2. Select an iOS 16+ iPhone or iPad simulator.
3. Build and run.

The project file is generated from `project.yml`; install [xcodegen](https://github.com/yonaskolb/XcodeGen) and run `xcodegen generate` to regenerate if needed.

## Schemes

Three shared schemes ship with the project. `StackOverflowUsers` is the default reviewer-friendly scheme; the suffixed schemes expose the environment-specific run/archive settings.

| Scheme | Run/archive configuration | Test configuration | Bundle ID | Display name |
|---|---|---|---|---|
| `StackOverflowUsers` | `Development` | `Development` | `com.brunovalente.StackOverflowUsers.dev` | `Stack Users Dev` |
| `StackOverflowUsers (Development)` | `Development` | `Development` | `com.brunovalente.StackOverflowUsers.dev` | `Stack Users Dev` |
| `StackOverflowUsers (Production)` | `Production` | `Development` | `com.brunovalente.StackOverflowUsers` | `Stack Users` |

The display name, bundle ID, API base URL, and optional Stack Apps API key flow through the xcconfig files into `Info.plist`. `Development.xcconfig` and `Production.xcconfig` optionally include `Config/Local.xcconfig`, which is git-ignored so a personal API key never ends up in the repo — `Config/Local.xcconfig.example` shows the shape.

## What It Does

- Fetches the top 20 users on launch, with infinite-scroll pagination that respects the API's `has_more` flag.
- Each row shows a circular avatar, display name, and locale-formatted reputation.
- Follow / unfollow toggles from a button tap, a leading swipe action, or a VoiceOver custom action. When followed, the row shows **both** a blue checkmark indicator and a tinted "Unfollow" button (the brief asks for an indicator *and* an unfollow option, so both are present at once).
- A segmented control below the navigation title filters between **All** and **Followed** users, and remains visible in empty/error states so the user can switch back.
- Tapping a row pushes a detail screen with a larger avatar, gold/silver/bronze badge pills, accept rate, location, and an "Open on Stack Overflow" button.
- The supplied Stack Overflow image is used as the app icon through the asset catalog's `AppIcon` set.
- A centered Stack Overflow splash screen is built in UIKit code; there is no launch storyboard.
- The last successful first-page response is cached on disk. Follow state persists in `UserDefaults`, keyed by `user_id`.
- Pull-to-refresh, adaptive Dynamic Type (cell flips to a vertical stack at accessibility sizes), and an accessibility announcement when the follow state flips.
- UIKit colors are centralized in `StackOverflowPalette`, using Stack Overflow brand stops for orange, blue, black, gray, and yellow while keeping neutral backgrounds dominant.
- Typography is centralized in `StackOverflowTypography`, mapping the Stack Overflow type scale onto Dynamic Type-aware UIKit fonts.

## Requirement Coverage

Direct map from the brief to where each item lives:

| Brief requirement | Where in the code |
|---|---|
| Top 20 users on launch | `UserListViewModel.load()` → `UserService.fetchTopUsers(page: 1, pageSize: 20)` |
| Profile image, name, reputation per cell | `UserCell.configure(with:imageLoader:onFollowTapped:)` |
| Follow option per cell | `followButton` on `UserCell` |
| Follow is local only, no API call | `UserDefaultsFollowRepository` (zero networking) |
| Follow indicator | `followedIndicator` (`checkmark.seal.fill`) |
| Unfollow when followed | Button flips to "Unfollow Name", red tinted style; swipe + VoiceOver action also available |
| Persistence across launches | `UserDefaults(suiteName:)` guarded by `OSAllocatedUnfairLock` |
| Error state with empty view | `EmptyStateView` + `AppError.userFacingMessage` |

## Error Handling — Three Distinct States

A single generic "something went wrong" would have passed the letter of the requirement, but the reviewer's spirit-of-the-brief question is usually *"does the app degrade intelligently?"*. So:

1. **`.stale(models, error)`** — we have disk cache, the network just failed. Shows the cached rows behind an orange "Showing saved users" banner; no retry dialog.
2. **`.failed(error, stale: [])`** — no in-memory rows, no cache. Full-screen `EmptyStateView` with a typed error message and a "Try Again" button.
3. **`.failed(error, stale: [rows])`** — we had rows in memory when the refresh failed. List stays on-screen, a retry alert appears over it.

`AppError` maps `URLError` / non-2xx HTTP / API error body / decoding failures to distinct user-facing strings, so each mode reads differently.

## Architecture

MVVM with a lightweight coordinator.

- `AppCoordinator` owns navigation.
- View controllers render state and forward intents; no business logic.
- View models hold all state and logic; **zero UIKit imports**.
- Data layer is protocol-backed: `UserServiceProtocol`, `FollowRepositoryProtocol`, `UserCacheProtocol`, `ImageLoading`. Makes every layer mockable without a framework.

```
StackOverflowUsers/
├── App/                      SceneDelegate, AppCoordinator
├── Domain/                   User, StackExchangeResponse, AppError (pure values)
├── Data/
│   ├── Network/              UserService
│   ├── Persistence/          UserDefaultsFollowRepository, FileUserCache
│   └── ImageLoading/         ImageLoader (actor), InitialsImageGenerator
├── Presentation/
│   ├── UserList/             ViewModel, ViewController, UserCell, FilterHeaderView
│   ├── UserDetail/           ViewModel, ViewController, BadgePillView
│   └── Shared/               EmptyStateView
└── Foundation/               String+HTMLEntities
```

## Technical Decisions

- **MVVM-C** picked to keep view models free of UIKit; alternatives (MVC, VIPER, TCA) were either too light or too heavy for the scope. TCA / any third-party was also ruled out by the brief.
- **Closure bindings** over Combine — fewer moving parts for a one-to-two-screen app; easy to port later.
- **`UserDefaults` for follow state** — the payload is `Set<Int>`; Core Data would be disproportionate. `FollowRepositoryProtocol` means swapping it later is a one-file change.
- **`FileUserCache`** writes the last successful list to disk as JSON. On network failure with no in-memory rows, the view model loads from disk and emits `.stale(models, error)` so the UI can show cached content behind a banner.
- **`ImageLoader` is an `actor`** — cache reads, writes, and in-flight request deduplication all happen inside the actor, so no locks or GCD queues in the image path. Bitmaps come back pre-rendered via `UIImage.preparingForDisplay()`.
- **Diffable data source keyed by `user_id`** — follow toggles update the single row via `snapshot.reconfigureItems(_:)`; avoids the full-list animation you'd get if `isFollowed` were part of the item hash.
- **`@MainActor`** on `UserListViewController`, `UserCell`, and the cell's image-load `Task` — guarantees UI mutations stay on the main thread and survives Thread Sanitizer clean.
- **Warnings treated as errors** (`SWIFT_TREAT_WARNINGS_AS_ERRORS = YES`, `GCC_TREAT_WARNINGS_AS_ERRORS = YES`, plus aggressive `CLANG_WARN_*` flags) in both configurations.

## API Schema Notes

The brief's schema doesn't match the live API in several places. The implementation deviates deliberately, and the deviations are worth calling out because they're exactly what a "read the API critically" reviewer looks for:

- **HTTPS, not HTTP.** The brief's example URL is `http://api.stackexchange.com/...`. iOS App Transport Security blocks plain HTTP; I used `https://` everywhere and added no `NSAllowsArbitraryLoads` exception (that would be a security regression).
- **Response envelope.** Stack Exchange wraps every payload in `{ items, has_more, quota_max, quota_remaining }`, with `error_id / error_name / error_message` appearing on API errors (often returned with HTTP 200). I decode `StackExchangeResponse<User>` first and check `wrapper.isAPIError` before reading `items`, so a throttle violation surfaces as `.apiError`, not a silent empty list.
- **`badge_counts.bronze` / `silver`.** Brief lists them as `String`; live API returns integers. Modelled as `Int?`. Decoding as `String` would have failed every user.
- **`accept_rate`.** Brief lists it as non-optional `Int`; actually absent on bot accounts and users who've never accepted an answer. Typed as `Int?` so one missing field can't nuke the whole response.
- **`link`.** Brief lists it as non-optional `String`; a single malformed URL would nuke the 19 other valid users if decoded strictly. Typed as `URL?` and treated as optional at the UI layer.
- **HTML entities.** `display_name` and `location` can arrive HTML-escaped (`Cura&#231;ao`, `Salvad&#243;`). Decoded once at the network boundary via `String.decodingHTMLEntities`, so the view model and cell never see raw entities.

## Testing

All tests run fully offline. Networking is stubbed via a `URLProtocol` subclass injected into `URLSessionConfiguration.ephemeral`; persistence uses ephemeral `UserDefaults(suiteName: UUID().uuidString)` suites and temp-directory cache files.

### Unit tests (`StackOverflowUsersTests`)

- **Decoding** — success wrapper, API-error wrapper, empty items, malformed JSON, integer badge counts, missing `accept_rate`, HTML entity decoding.
- **Networking** — HTTPS URL assembly with the expected query items, page / pageSize parameters, 2xx / 5xx, API-error body at HTTP 200, malformed body, empty items, transport failure.
- **Image loader** — success path, HTTP error, transport error, cache hit, in-flight deduplication.
- **Follow repository** — follow / unfollow / toggle, persistence across re-instantiation, 100-way concurrent writes, ephemeral suite isolation.
- **File user cache** — round-trip save/load, missing-file nil, overwrite, clear.
- **List view model** — loading → loaded transitions, every error shape, stale preservation, cache fallback, initial followed state, follow toggling, All/Followed filter (including the empty variant), pagination append / has-more stop / filter guard.
- **Detail view model** — reputation formatting, whitespace-trimmed location, nil-vs-zero badge counts, accept-rate suffix, profile-URL pass-through.
- **Cell model** — locale-aware thousands separator, small numbers unseparated, always ends with `" rep"`.
- **State presenter** — empty titles and error titles are distinct, non-empty, and free of technical jargon.
- **App error** — each case produces a distinct user-facing message; status codes and API names are included where relevant.
- **Initials generator** — deterministic PNG output for the same name, different names produce different colours, empty/whitespace input falls back safely.

### End-to-end UI tests (`StackOverflowUsersUITests`)

Six XCUITest cases driven by a debug-only `-UITests` launch flag that swaps in a stub service and an ephemeral follow store:

- Launch renders the top users.
- Launch with a simulated network failure renders the offline empty state and retry action.
- Tapping follow flips the composed accessibility label and shows the "Unfollow" button.
- Followed filter shows the "No followed users yet" empty state when nothing is followed, then switches back to All.
- Follow-then-filter shows only the followed user.
- Tapping a row pushes the detail with an Open-profile button.

### Running them

```bash
xcodebuild -project StackOverflowUsers.xcodeproj \
  -scheme 'StackOverflowUsers' \
  -destination 'platform=iOS Simulator,name=iPhone 16' test
```

The Production scheme keeps its Test action on the Development configuration so `@testable import` remains available. To verify the release-optimised app build, run:

```bash
xcodebuild -project StackOverflowUsers.xcodeproj \
  -scheme 'StackOverflowUsers (Production)' \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Tradeoffs

I prioritised:

- Clean separation between networking, persistence, presentation, and domain.
- Testable view models and protocol-backed data layer.
- Graceful degradation — stale cache, typed errors, retry UX.

I deliberately avoided:

- A generic HTTP client or interceptor chain.
- Core Data or any heavier persistence stack for a `Set<Int>` follow store.
- Third-party libraries of any kind, including mocking frameworks in the test target.

Given more time, I'd add a full on-device accessibility audit with the Accessibility Inspector at the largest accessibility sizes, a persistent image cache (memory-only today), and snapshot tests for the cell layout at Dynamic Type extremes.

## Notes for the Reviewer

- **Stack Exchange rate limit.** Unauthenticated requests are capped at 300/day per IP. If the API returns a `throttle_violation`, the app surfaces it via `.apiError`. To lift the limit to 10 000/day, copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig` and paste in a free [Stack Apps key](https://stackapps.com/apps/oauth/register).
- **Gravatar over HTTP.** Some `profile_image` URLs are `http://` Gravatar links. ATS blocks them; the app falls back to a deterministically-coloured initials placeholder. Not adding an ATS exception — that would be a security regression for a few avatars.
- **No CI.** No GitHub Actions workflow is committed. Tests run locally with the `xcodebuild` line above.

## Reviewer Guide

Quickest path through the code:

- `UserListViewModel` — state machine and intents
- `UserService` — URL assembly, decoding, error mapping
- `FollowRepository` + `FileUserCache` — persistence and offline fallback
- `ImageLoader` — actor-based image cache with in-flight dedup
- `UserDetailViewModel` + `BadgePillView` — detail-screen value formatting

---

Bruno Valente
