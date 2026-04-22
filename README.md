# Stack Overflow Users

An iOS application that fetches and displays the top Stack Overflow users, built with a testable MVVM architecture in UIKit.

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

## What the App Does

- Fetches the top 20 Stack Overflow users on launch.
- Each row shows a profile image, display name, and formatted reputation.
- Follow / unfollow any user locally — no API call is made. Followed users show a visual indicator and the button changes to offer an unfollow action; VoiceOver labels and custom actions are supported.
- Follow state persists between sessions.
- When the network is unavailable, the app shows a clear error message with a retry button.

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
│   ├── UserList/             ViewModel, ViewController, UserCell
│   ├── UserDetail/           ViewModel, ViewController
│   └── Shared/               EmptyStateView
└── Foundation/               String+HTMLEntities
```

Data flow:

```
ViewController → ViewModel → Repository / Service → API / Local Storage
```

## Technical Decisions

- **MVVM + Coordinator** — keeps view controllers thin and view models free of UIKit, so they can be unit-tested directly. Navigation lives in the coordinator, not scattered across view controllers.
- **Protocol-backed data layer** — all dependencies are injected via protocols; no singletons. Every layer can be replaced with a test double without a mocking framework.
- **`UserDefaults` for follow state** — the payload is a `Set<Int>`; Core Data would be disproportionate. `FollowRepositoryProtocol` isolates the storage choice so swapping it later is a one-file change.
- **Closure bindings** — straightforward ViewModel → ViewController communication for a two-screen app; no reactive framework needed.

## Testing

All tests run fully offline. Networking is stubbed via a `URLProtocol` subclass; persistence uses ephemeral `UserDefaults` suites and temp-directory cache files.

**Unit tests** cover decoding, networking, image loading, follow repository, file cache, list view model state transitions and filters, detail view model, cell formatting, error copy, and initials generation.

**UI tests** (eight XCUITest cases) cover launch, offline state, follow/unfollow interaction, filter behavior, detail navigation, and portrait/landscape layout — driven by a debug launch flag that injects a stub service. Tests pass on both iPhone and iPad simulators.

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

Prioritised clean layer separation, dependency injection, and unit-testable view models. Chose `UserDefaults` over Core Data because the data model is trivial. Avoided third-party libraries for both production and test code, as the brief required.

## Notes

- The Stack Exchange API requires HTTPS; no `NSAllowsArbitraryLoads` exception is added.
- Some API fields listed in the brief schema are optional or typed differently in the live API; the implementation handles these defensively (`accept_rate` is optional, badge counts are integers, display names may be HTML-escaped).
- Gravatar profile image URLs may use `http://`; these fall back to a deterministically-coloured initials placeholder rather than adding an ATS exception.
- Unauthenticated requests are capped at 300/day per IP. Copy `Config/Local.xcconfig.example` → `Config/Local.xcconfig` and add a free [Stack Apps key](https://stackapps.com/apps/oauth/register) to raise the limit.

## Reviewer Guide

Quickest path through the required flow:

- `UserListViewModel` — state machine, loading, and follow intents
- `UserService` — URL assembly, decoding, error mapping
- `UserDefaultsFollowRepository` — follow persistence
- `UserCell` — cell configuration and follow UI

---

Bruno Valente
