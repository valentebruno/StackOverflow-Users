# Stack Overflow Users

An iOS application that fetches and displays the top Stack Overflow users.

Focused on clean architecture, testability, and predictable state handling within a scope aligned with the original exercise.

## Requirements

- Xcode 16 or newer
- iOS 16.0 deployment target
- Swift 5.9+
- UIKit only
- No third-party dependencies

## Running the App

1. Open `StackOverflowUsers.xcodeproj`.
2. Select an iOS 16+ simulator.
3. Build and run (`⌘R`).

The project is generated from `project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen); run `xcodegen generate` to regenerate if needed. Three shared schemes are included — `StackOverflowUsers` is the default and covers all tests.

## Core Functionality

- Fetches the top 20 Stack Overflow users on launch.
- Each row shows a profile image, display name, and formatted reputation.
- Follow / unfollow users locally — no API call is made. Followed users show a tinted avatar ring and a distinct unfollow button simultaneously. VoiceOver labels and custom actions are supported.
- Follow state persists between sessions.
- Network failure shows a clear error state with a retry action; cached data is shown where available.

## Requirement Coverage

| Brief requirement | Implementation |
|---|---|
| Top 20 users on launch | `UserListViewModel.load()` → `UserService.fetchTopUsers(page:1, pageSize:20)` |
| Profile image, name, reputation | `UserCell.configure(with:imageLoader:onFollowTapped:)` |
| Follow option per cell | `followButton` on `UserCell` |
| Follow is local only | `UserDefaultsFollowRepository` (zero networking) |
| Follow indicator | Avatar ring tint + button tint flip |
| Unfollow when followed | Same button; also via leading swipe and VoiceOver action |
| Persistence across launches | `UserDefaults` keyed by `user_id` |
| Error state with message | `EmptyStateView` + `AppError.userFacingMessage` |

## Architecture

MVVM with a lightweight coordinator.

- **View controllers** render state and forward user intents; no business logic.
- **View models** own all state and logic; zero UIKit imports, fully unit-testable.
- **Coordinator** owns navigation and wires dependencies at the composition root.
- **Data layer** is protocol-backed — `UserServiceProtocol`, `FollowRepositoryProtocol`, `UserCacheProtocol`, `ImageLoading` — so every layer is mockable without a framework.

```
StackOverflowUsers/
├── App/                      SceneDelegate, AppCoordinator
├── Domain/                   User, StackExchangeResponse, AppError
├── Data/
│   ├── Network/              UserService
│   ├── Persistence/          UserDefaultsFollowRepository, FileUserCache
│   └── ImageLoading/         ImageLoader, InitialsImageGenerator
├── Presentation/
│   ├── UserList/             ViewModel, ViewController, UserCell, FilterHeaderView
│   ├── UserDetail/           ViewModel, ViewController, BadgePillView
│   └── Shared/               EmptyStateView
└── Foundation/               String+HTMLEntities
```

Data flow:

```
ViewController → ViewModel → Repository / Service → API / Local Storage
```

## Technical Decisions

- **MVVM + Coordinator** — keeps view controllers thin, view models testable, and navigation separate. Avoids the Massive ViewController pattern without requiring VIPER or a third-party architecture framework.
- **Protocol-backed data layer** — every dependency is injected via a protocol; no singletons. Enables mocking without a test framework.
- **`UserDefaults` for follow state** — the payload is `Set<Int>`; Core Data would be disproportionate. `FollowRepositoryProtocol` makes swapping it a one-file change.
- **Disk cache for offline fallback** — `FileUserCache` stores the last successful response as JSON. On launch without a network, users see cached content rather than a blank screen.
- **`ImageLoader` actor** — cache reads, writes, and in-flight deduplication are isolated inside the actor; no manual locking needed at call sites.
- **Diffable data source** — follow toggles update only the affected row; avoids full-list reloads on state change.

## Error Handling

Three distinct failure states, each with a different UI response:

1. **Stale cache** — network failed but disk cache is available. Cached rows are shown with a banner indicating data may be out of date.
2. **Hard failure, no cache** — full-screen error view with a message and a "Try Again" button.
3. **Refresh failure over existing content** — current list stays visible; an alert offers a retry.

## Testing

All tests run fully offline. Networking is stubbed via a `URLProtocol` subclass; persistence uses ephemeral `UserDefaults` suites and temp-directory cache files.

**Unit tests** cover decoding, networking, image loading, follow repository, file cache, list view model state transitions and filters, detail view model, cell formatting, error copy, and initials generation.

**UI tests** (six XCUITest cases) cover launch, offline state, follow/unfollow interaction, filter behavior, and detail navigation — driven by a debug launch flag that injects a stub service. Tests pass on both iPhone and iPad simulators.

```bash
# iPhone
xcodebuild -project StackOverflowUsers.xcodeproj \
  -scheme 'StackOverflowUsers' \
  -destination 'platform=iOS Simulator,name=iPhone 17' test

# iPad
xcodebuild -project StackOverflowUsers.xcodeproj \
  -scheme 'StackOverflowUsers' \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' test
```

## Tradeoffs

Prioritised correctness, clean separation, and testability for the core requirements. A few lightweight additions — offline cache, a detail screen, pull-to-refresh, segmented filter, and accessibility support — were included where they improved resilience or usability without adding architectural complexity or third-party dependencies.

Deliberately avoided: generic HTTP interceptor chains, Core Data for a simple key-value follow store, and snapshot tests (acceptable tradeoff at this scope).

## Notes

- The Stack Exchange API requires HTTPS; no `NSAllowsArbitraryLoads` exception is added.
- Some API fields listed in the brief schema are optional or typed differently in the live API; the implementation handles these defensively (optional `accept_rate`, integer badge counts, HTML-escaped display names).
- Gravatar URLs may use `http://`; these fall back to a deterministically-coloured initials placeholder rather than adding an ATS exception.
- Unauthenticated requests are capped at 300/day per IP. Copy `Config/Local.xcconfig.example` → `Config/Local.xcconfig` and add a free [Stack Apps key](https://stackapps.com/apps/oauth/register) to raise the limit.

## Reviewer Guide

Quickest path through the code:

- `UserListViewModel` — state machine and user intents
- `UserService` — URL assembly, decoding, error mapping
- `UserDefaultsFollowRepository` + `FileUserCache` — persistence and offline fallback
- `ImageLoader` — actor-based image cache
- `UserDetailViewModel` + `BadgePillView` — detail screen

---

Bruno Valente
