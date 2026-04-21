# Stack Overflow Users

A small iOS app that shows the top 20 Stack Overflow users by reputation and lets you follow or unfollow them locally.

## Requirements

- Xcode 15 or newer
- **Deployment target: iOS 16.0** (uses `OSAllocatedUnfairLock`, `UIButton.Configuration`, `UIImage.preparingForDisplay()`, and diffable `reconfigureItems(_:)`, all of which require iOS 15+; I picked iOS 16 to keep modern concurrency APIs available without caveats).
- Swift 5.9+ — plain `async throws`, no typed `throws(_:)`.
- No third-party dependencies.

## Running

```bash
open StackOverflowUsers.xcodeproj
```

Pick an iOS 16+ iPhone simulator and hit run. The `StackOverflowUsers` scheme is checked into `xcshareddata` so it shows up automatically after a fresh clone. If you'd rather (re)generate the project from scratch, install [xcodegen](https://github.com/yonaskolb/XcodeGen) and run `xcodegen generate` — `project.yml` is the source of truth for the project file.

The target is iPhone-only in portrait. I scoped it deliberately rather than shipping an untested Universal layout — the rest of the checklist matters more at this scope.

## What it does

- Fetches the top 20 users from `https://api.stackexchange.com/2.2/users?order=desc&sort=reputation&site=stackoverflow` on launch and appends the next page as you scroll (infinite scroll, respects the API's `has_more` flag).
- Renders each user with a circular avatar, display name, and locale-formatted reputation.
- A tap on the follow button (or a leading swipe) toggles follow state. Followed rows show both a blue checkmark indicator and a tinted "Unfollow" button — the spec asks for an indicator *and* an unfollow option, so both are present at once.
- A table-header segmented control toggles between **All** and **Followed**. When the filter yields nothing, a dedicated "No followed users yet" empty state is rendered (no retry button — it's not an error).
- Follow state is keyed by `user_id` and persists across launches.
- The last successful first-page response is cached on disk. When the network fails and nothing is already in memory, the app shows the cached users behind an orange "Showing saved users" banner instead of a full-screen empty state.
- On failure — offline, non-2xx, API error body, decoding — the app keeps any previously loaded rows and surfaces a retry alert. With no stale data and no cache, it falls back to a full-screen empty state with a "Try Again" button. Pull-to-refresh is also wired up.

## Architecture

MVVM with a lightweight coordinator.

```
App/                Scene + coordinator bootstrap
Domain/             User, StackExchangeResponse, AppError — pure value types
Data/
  Network/          UserService: URLSession + decoder, maps errors into AppError
  Persistence/      UserDefaultsFollowRepository: Set<Int> behind an unfair lock
                    FileUserCache: JSON-on-disk cache for offline fallback
  ImageLoading/     ImageLoader actor: NSCache + in-flight dedup
Presentation/
  UserList/         View model, view controller, cell, cell model
  Shared/           EmptyStateView
Foundation/         String+HTMLEntities
```

A few things worth calling out:

**The view model has no UIKit import.** It exposes a `ViewState` enum (`idle / loading / loaded / stale / empty / failed`) through a closure. That's enough to test every state transition without touching a table view. I went with a closure rather than Combine because the surface area doesn't justify the extra concept; it's easy to port later if the app grows.

**`ImageLoader` is an actor** so cache reads/writes and in-flight deduplication don't need explicit locking. When two cells request the same avatar URL concurrently, the second call awaits the first task rather than firing a duplicate request. Decoded bitmaps come back via `UIImage.preparingForDisplay()` so the main thread only sees pre-rendered images. Cancellation happens from the cell's `prepareForReuse` — the `Task` returned from `configure` is held directly on the cell (no Objective-C associated objects).

**`FollowRepository` uses `OSAllocatedUnfairLock`** around the in-memory set of user IDs and writes through to `UserDefaults`. UserDefaults is proportionate here — the payload is a set of ints. A future Core Data migration is a one-file change because everything goes through `FollowRepositoryProtocol`.

**Diffable data source keyed by `user_id`.** Item identity is the user ID only; follow toggles and other row-local changes flow through `snapshot.reconfigureItems(_:)`, which avoids the full-list animation you get when `isFollowed` is part of the item hash.

**UIKit classes are explicitly `@MainActor`.** `UserListViewController`, `UserCell`, and `EmptyStateView` are all pinned to the main actor, and the cell's image-load `Task` is `@MainActor` so UI mutations can't accidentally run on a background thread — this survives Thread Sanitizer cleanly.

## API notes

A few things don't line up with the simplified schema in the brief, and I handled each explicitly:

- The endpoint in the brief is `http://`. I used `https://` to avoid App Transport Security rejections. **No `NSAllowsArbitraryLoads` exception is added.**
- The real response is wrapped in a common envelope (`items`, `has_more`, `quota_max`, `quota_remaining`, plus `error_id / error_name / error_message` on failure). I decode `StackExchangeResponse<User>` first and only then read `items`. An API error body with HTTP 200 is surfaced as `.apiError`, not a decoding failure.
- `badge_counts.bronze` and `silver` are documented as `String` in the brief but the live API returns integers. `BadgeCounts` models them as `Int?`.
- `accept_rate` is marked non-optional in the brief but is absent for bot accounts and users without accepted answers. It (and every field we don't strictly need, including `link`) is `Optional` so a single malformed record can't nuke the other nineteen.
- `display_name` and `location` can come back with HTML entities like `Cura&#231;ao`. They're decoded once at the network boundary via `String.decodingHTMLEntities`.

### Rate limiting

The app calls the Stack Exchange v2.2 API without an API key, which is capped at **300 requests/day per IP**. Running the app a couple of times while reviewing it is fine, but if a shared office IP has already burnt through the quota, you'll see the `.apiError` state with a `throttle_violation` message — that's the API talking, not a bug in the app. Registering a free Stack Apps key would lift the ceiling to 10,000/day, but I deliberately didn't hardcode a personal key in the repo.

### Gravatar & HTTP profile images

Some users' `profile_image` URLs still point to Gravatar over plain `http://`. ATS silently blocks those, and the app falls back to a deterministically-coloured initials placeholder. This is the correct behaviour — loosening ATS for the whole app to fix a few avatars would be a security regression, so I left it.

## Tests

GitHub Actions workflow: [`.github/workflows/ios.yml`](.github/workflows/ios.yml) — `macos-latest`, picks the newest available iPhone simulator at runtime, runs `build-for-testing` then `test-without-building`, and uploads the `.xcresult` bundle as an artifact.

To run the same thing locally:

```bash
xcodebuild -project StackOverflowUsers.xcodeproj \
  -scheme StackOverflowUsers \
  -destination 'platform=iOS Simulator,name=iPhone 16' test
```

All XCTest cases live in the test target and run offline:

- `DecodingTests` — success wrapper, API error wrapper, empty items, malformed JSON, badge count integers, missing `accept_rate`, HTML entity decoding.
- `UserServiceTests` — stubbed `URLSession` via `URLProtocol` covering HTTPS request shape, page/pageSize query items, 2xx, 5xx, API error body, malformed body, empty items, and transport failure.
- `ImageLoaderTests` — success, HTTP error, transport error, cache hit, and in-flight deduplication.
- `FollowRepositoryTests` — follow/unfollow/toggle, persistence across reinstantiation, and 100-way concurrent writes against an ephemeral `UserDefaults(suiteName:)` suite.
- `FileUserCacheTests` — round-trip save/load, missing-file nil, overwrite, and clear against a scoped temp directory.
- `UserListViewModelTests` — state transitions for success and every error shape, stale preservation across failures, cache fallback, initial followed state, follow toggling, All/Followed filter transitions, and pagination (append, has_more stop, filter guard).

No live network calls, no third-party mocking library — `URLProtocol` stubs and plain `XCTestCase` everywhere.

## What I'd add with more time

- **Full accessibility audit on device.** VoiceOver labels, custom actions, and Dynamic Type support are in place, but a pass with the Accessibility Inspector at the largest accessibility sizes would surface improvements (particularly announcements for the follow state transition and image-load state). Relevant to European Accessibility Act compliance coming into force in 2025.
- **Dynamic Type at extreme sizes.** All labels use `preferredFont(forTextStyle:)` with `adjustsFontForContentSizeCategory = true` and `automaticDimension` row heights, but the layout at the accessibility sizes (XXXL+) should still be verified on a physical device with the Accessibility Inspector.
- **User detail screen** with badges, location, and the Stack Overflow profile link.
- **Image coalescence across rapid scrolling.** The `ImageLoader` already deduplicates in-flight requests by URL, but a short backoff on cell reuse (wait a few hundred milliseconds before firing) would further reduce redundant fetches during fast flicks.
- **Treat warnings as errors.** `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` in release builds would lock in the current zero-warning state.
- **Stack Apps API key.** Registering a free key and plumbing it through a build setting would lift the 300/day IP quota to 10,000/day for reviewers on shared IPs.

## Author

Bruno Valente
