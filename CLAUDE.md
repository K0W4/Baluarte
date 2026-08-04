# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

App DeMolay is a native iOS SwiftUI app (iOS 26+) for managing DeMolay Chapters: attendance/roster, event scheduling, gamified goals, tasks, committees, and on-device AI-generated insights. Backend is Supabase (Postgres/PostgREST) with Row Level Security; the only third-party dependency is `supabase-swift` (SPM) — everything else favors native Apple frameworks (EventKit, AppIntents, WidgetKit, NaturalLanguage/Foundation Models) per the project's YAGNI/native-first philosophy.

## Commands

Build and test via `xcodebuild` (no Package.swift/Makefile at the root — this is an Xcode project, `App DeMolay.xcodeproj`).

```bash
xcodebuild -scheme "App DeMolay" -destination 'platform=iOS Simulator,name=iPhone 16' build
```

```bash
xcodebuild -scheme "App DeMolay" -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Run a single test class or method (`-only-testing`):

```bash
xcodebuild -scheme "App DeMolay" -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:App_DeMolayTests/HomeViewModelTests
```

```bash
xcodebuild -scheme "App DeMolay" -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:App_DeMolayTests/HomeViewModelTests/testSomeMethod
```

Targets: `App DeMolay` (app), `App DeMolayTests` (unit tests), `App DeMolayUITests` (UI tests), `AppDeMolayWidgetsExtension` (WidgetKit extension, own scheme).

Requires Xcode 26+ and an active Supabase project. `App DeMolay/Core/SupabaseSecrets.swift` is gitignored and must exist locally (provides `SupabaseSecrets.projectURL`/`anonKey`); `Config.xcconfig` + `setup_xcconfig.rb` wire equivalent keys into `Info.plist` build settings.

## Architecture

**MVVM, strictly.** Models → Views → ViewModels → Services (protocol-oriented), per `.agents/AGENTS.md`:

- **Models** (`Models/`): plain `Codable`/`Identifiable`/`Hashable` structs, no logic. `CodingKeys` map to the database's `snake_case`.
- **Views** (`Views/<Feature>/`): zero business logic. A view owns `@State private var viewModel = XxxViewModel()` and only calls ViewModel methods from actions/`.task`/`.onAppear`.
- **ViewModels** (`ViewModels/<Feature>/`): `@Observable` (never legacy `@ObservableObject`/`@Published`). One per main View. Hold all business logic and receive services via protocol-typed `init` params defaulting to the real implementation (e.g. `AuthViewModel.init(authService: AuthServiceProtocol = AuthService(), memberService: MemberServiceProtocol = Services.member)`), which is what makes them independently testable with mocks.
- **Services** (`Services/`, protocols in `Services/Protocols/`): every external data source (Supabase, EventKit, on-device ML) is accessed through a protocol with a real Supabase-backed implementation and a Mock counterpart used in tests/`App DeMolayTests/Mocks/`. `Core/Services.swift` is the composition root — a `Services` struct exposing the shared singleton instance of each protocol (`Services.event`, `.goal`, `.member`, `.task`, `.committee`, `.chapter`, `.intelligence`).
- **Core/**: app entry point (`AppDeMolay.swift`, `@main`) plus cross-cutting singletons — `SupabaseManager` (wraps `SupabaseClient`), `KeychainHelper` (Keychain-backed secure storage), `EventKitManager`, `WidgetManager`, `UserDefaultsManager`, `HapticManager`, `AppError`.
- **DesignSystem/**: `Theme` (semantic colors), `Typography` (type scale), `Spacing` (spacing tokens), and `Components/{Buttons,Cards}` for reusable visual pieces. Views must not use literal colors, `.font(.system(size:))`, or magic padding values — always go through Theme/Typography/Spacing.

**App flow / navigation state machine**: `RootView` (`Views/Shared/RootView.swift`) switches on `AuthViewModel.state` (`.loading` / `.unauthenticated` / `.authenticated(User, Member?)`) to route between `OnboardingView` → `LoginView` → `ChapterSelectionView` (when the authenticated member has no `chapterId`) → `ContentView` (main `TabView`). `AuthViewModel` is injected app-wide via `@Environment` from `AppDeMolay.swift`.

**Dependency injection**: services flow into ViewModels via protocol-typed initializer params (default = real impl); `AuthViewModel` itself is injected into Views via `@Environment`, not passed down manually.

**Navigation**: `NavigationStack` with value-based routes only — `NavigationView` is banned.

**Extensions beyond the main app target**: `Intents/` holds AppIntents (Siri Shortcuts, e.g. `ConfirmAttendanceIntent`, `NextEventIntent`) and `AppDeMolayWidgets/` is a separate WidgetKit extension target with its own data manager (`WidgetDataManager`) reading data the `event` table exposes to anonymous/public reads for widget use.

## Conventions (from `.agents/AGENTS.md`)

- No force unwrapping (`!`) anywhere — use `if let`/`guard let`/`??`.
- `async/await` for async work; `@MainActor` is required on ViewModel methods that mutate UI state.
- Break up large view `body`s into separate reusable structs (prefer this over `some View`-returning helper functions), placed in `DesignSystem/Components/` when generic.
- No inline `//` comments except `MARK:` in long files — code should be self-explanatory through naming.
- Optimistic UI updates for toggle/quick-update interactions (apply immediately, revert on API failure).
- UI/UX changes must account for Nielsen's heuristics, WCAG (contrast, 44x44pt touch targets, VoiceOver/Dynamic Type), and cognitive-load principles (Hick's Law, Von Restorff effect) — this is treated as mandatory, not optional polish.
- Unit tests cover ViewModels and Models only (business logic, data transforms, computed properties); Mocks under `App DeMolayTests/Mocks/` must stay deterministic.
- Git commit messages must be written in English following Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`), even though chat/docs are in Portuguese (pt-BR).
- Native-first: exhaust native iOS/SwiftUI APIs (EventKit, Foundation Models, AppIntents, WidgetKit) before adding any third-party SPM dependency.
