# Stack Overflow Users

A small iOS app that shows the top 20 Stack Overflow users by reputation and lets you follow or unfollow them locally.

## Requirements

- Xcode 15 or newer
- iOS 16+ simulator or device
- No third-party dependencies

## Running

```bash
open StackOverflowUsers.xcodeproj
```

Pick an iOS 16+ simulator and hit run. If you'd rather (re)generate the project from scratch, install [xcodegen](https://github.com/yonaskolb/XcodeGen) and run `xcodegen generate` — `project.yml` is the source of truth for the project file.

## What it does

- Fetches the top 20 users from `https://api.stackexchange.com/2.2/users?order=desc&sort=reputation&site=stackoverflow` on launch.
- Renders each user with a circular avatar, display name, and locale-formatted reputation.
- A tap on the follow button (or a leading swipe) toggles follow state. Followed rows show a checkmark and an "Unfollow" action.
- Follow state is keyed by `user_id` and persists across launches.
- On failure — offline, non-2xx, API error body, decoding — the app keeps any previously loaded rows and shows a retry alert. With no stale data, it falls back to a full-screen empty state with a "Try Again" button. Pull-to-refresh is also wired up.

## Architecture

MVVM with a lightweight coordinator.

```
App/                Scene + coordinator bootstrap
Domain/             User, StackExchangeResponse, AppError — pure value types
Data/
  Network/          UserService: URLSession + decoder, maps errors into AppError
  Persistence/      UserDefaultsFollowRepository: Set<Int> behind an unfair lock
  ImageLoading/     ImageLoader actor: NSCache + in-flight dedup
Presentation/
  UserList/         View model, view controller, cell, cell model
  Shared/           EmptyStateView
Foundation/         String+HTMLEntities
```

A few things worth calling out:

**The view model has no UIKit import.** It exposes a `ViewState` enum (`idle / loading / loaded([UserCellModel]) / failed(AppError, stale: [UserCellModel])`) through a closure. That's enough to test every state transition without touching a table view. I went with a closure rather than Combine because the surface area doesn't justify the extra concept; it's easy to port later if the app grows.

**`ImageLoader` is an actor** so cache reads/writes and in-flight deduplication don't need explicit locking. It hands decoded bitmaps back via `UIImage.preparingForDisplay()` so the main thread only sees pre-rendered images. Cancellation happens from the cell's `prepareForReuse` — the `Task` returned from `configure` is held directly on the cell (no associated objects).

**`FollowRepository` uses `OSAllocatedUnfairLock`** around the in-memory set of user IDs and writes through to `UserDefaults`. UserDefaults is proportionate here — the payload is a set of ints. A future Core Data migration is a one-file change because everything goes through `FollowRepositoryProtocol`.

**Diffable data source keyed by `user_id`.** Item identity is the user ID only; follow toggles and other row-local changes flow through `snapshot.reconfigureItems(_:)`, which avoids the full-list animation you get when `isFollowed` is part of the item hash.

## API notes

A few things don't line up with the simplified schema in the brief, and I handled each explicitly:

- The endpoint in the brief is `http://`. I used `https://` to avoid App Transport Security rejections.
- The real response is wrapped in a common envelope (`items`, `has_more`, `quota_max`, `quota_remaining`, plus `error_id / error_name / error_message` on failure). I decode `StackExchangeResponse<User>` first and only then read `items`. An API error body with HTTP 200 is surfaced as `.apiError`, not a decoding failure.
- `badge_counts.bronze` and `silver` are documented as `String` in the brief but the live API returns integers. `BadgeCounts` models them as `Int?`.
- `accept_rate` is marked non-optional in the brief but is absent for bot accounts and users without accepted answers. It (and every field we don't strictly need) is `Optional`.
- `display_name` and `location` can come back with HTML entities like `Cura&#231;ao`. They're decoded once at the network boundary via `String.decodingHTMLEntities`.

## Tests

```bash
xcodebuild -project StackOverflowUsers.xcodeproj \
  -scheme StackOverflowUsers \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

34 XCTest cases across five targets:

- `DecodingTests` — success wrapper, API error wrapper, empty items, malformed JSON, badge count integers, missing `accept_rate`, HTML entity decoding.
- `UserServiceTests` — stubbed `URLSession` via `URLProtocol` covering 2xx, 5xx, API error body, malformed body, empty items, and transport failure.
- `ImageLoaderTests` — success, HTTP error, transport error, cache hit, and in-flight deduplication.
- `FollowRepositoryTests` — follow/unfollow/toggle, persistence across reinstantiation, and 100-way concurrent writes against an ephemeral `UserDefaults` suite.
- `UserListViewModelTests` — state transitions for success and every error shape, stale preservation across failures, initial followed state, and follow toggling.

No live network calls and no third-party mocking library.

## What I'd add with more time

- Pagination with `page` / `pagesize`. The service and view model already hold the users array; adding a `loadNextPage()` intent and a scroll trigger in the view controller is small.
- Offline cache of the last successful response on disk so the first launch after a cold start with no network shows rows with a banner rather than an empty state.
- An accessibility pass with the Accessibility Inspector. VoiceOver labels exist, but I'd want to audit rotor order and announcements on follow.
- A user detail screen with badges, location, and the StackOverflow profile link.

## Author

Bruno Valente
