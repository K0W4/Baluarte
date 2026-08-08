# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Baluarte is a native iOS SwiftUI app (iOS 26+) for managing DeMolay Chapters: attendance/roster, event scheduling, gamified goals, tasks, committees, and on-device AI-generated insights. Backend is Supabase (Postgres/PostgREST) with Row Level Security; the only third-party dependency is `supabase-swift` (SPM) — everything else favors native Apple frameworks (EventKit, AppIntents, WidgetKit, NaturalLanguage/Foundation Models) per the project's YAGNI/native-first philosophy.

## Commands

Build and test via `xcodebuild` (no Package.swift/Makefile at the root — this is an Xcode project, `Baluarte.xcodeproj`).

```bash
xcodebuild -scheme Baluarte -destination 'platform=iOS Simulator,name=iPhone 17' build
```

```bash
xcodebuild -scheme Baluarte -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Run a single test class or method (`-only-testing`):

```bash
xcodebuild -scheme Baluarte -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:BaluarteTests/HomeViewModelTests
```

```bash
xcodebuild -scheme Baluarte -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:BaluarteTests/HomeViewModelTests/testSomeMethod
```

Targets: `Baluarte` (app), `BaluarteTests` (unit tests), `BaluarteUITests` (UI tests), `BaluarteWidgetsExtension` (WidgetKit extension, own scheme).

Requires Xcode 26+ and an active Supabase project. `Baluarte/Core/SupabaseSecrets.swift` is gitignored and must exist locally (provides `SupabaseSecrets.projectURL`/`anonKey`); `Config.xcconfig` + `setup_xcconfig.rb` wire equivalent keys into `Info.plist` build settings.

Database schema is versioned in `supabase/migrations/` and applied with the Supabase CLI. Never change schema, RLS policies or grants through the dashboard — write a migration so the change is reviewable and replayable.

```bash
supabase db push
```

## Architecture

**MVVM, strictly.** Models → Views → ViewModels → Services (protocol-oriented), per `.agents/AGENTS.md`:

- **Models** (`Models/`): plain `Codable`/`Identifiable`/`Hashable` structs, no logic. `CodingKeys` map to the database's `snake_case`.
- **Views** (`Views/<Feature>/`): zero business logic. A view owns `@State private var viewModel = XxxViewModel()` and only calls ViewModel methods from actions/`.task`/`.onAppear`.
- **ViewModels** (`ViewModels/<Feature>/`): `@Observable` (never legacy `@ObservableObject`/`@Published`). One per main View. Hold all business logic and receive services via protocol-typed `init` params defaulting to the real implementation (e.g. `AuthViewModel.init(authService: AuthServiceProtocol = AuthService(), memberService: MemberServiceProtocol = Services.member)`), which is what makes them independently testable with mocks.
- **Services** (`Services/`, protocols in `Services/Protocols/`): every external data source (Supabase, EventKit, on-device ML) is accessed through a protocol with a real Supabase-backed implementation and a Mock counterpart used in tests/`BaluarteTests/Mocks/`. `Core/Services.swift` is the composition root — a `Services` struct exposing the shared singleton instance of each protocol (`Services.event`, `.goal`, `.member`, `.profile`, `.membership`, `.task`, `.committee`, `.chapter`, `.intelligence`).
- **Core/**: app entry point (`BaluarteApp.swift`, `@main`) plus cross-cutting singletons — `SupabaseManager` (wraps `SupabaseClient`), `KeychainHelper` (Keychain-backed secure storage), `EventKitManager`, `WidgetManager`, `UserDefaultsManager`, `HapticManager`, `AppError`.
- **DesignSystem/**: `Theme` (semantic colors), `Typography` (type scale), `Spacing` (spacing tokens), and `Components/{Buttons,Cards}` for reusable visual pieces. Views must not use literal colors, `.font(.system(size:))`, or magic padding values — always go through Theme/Typography/Spacing.

**App flow / navigation state machine**: `RootView` (`Views/Shared/RootView.swift`) switches on `AuthViewModel.route` (`RootRoute`: `.loading` / `.unauthenticated` / `.chapterSelection` / `.app`) to route between `OnboardingView` → `LoginView` → `ChapterSelectionView` (when the person has no active membership) → `ContentView` (main `TabView`). `AuthViewModel` is injected app-wide via `@Environment` from `BaluarteApp.swift`.

**Membership, identity and permissions** — the three distinctions the whole data model rests on:

- **Person vs. bond.** `UserProfile` is the person (one row per `auth.users` entry, table `member`). `ChapterMembership` is their bond with a chapter (table `chapter_membership`, N:N, capped at 2 active by a trigger — double affiliation). A membership with `member_id IS NULL` is a roster entry for someone who has no account yet.
- **Membership id is the chapter-scoped actor id.** `committee.member_ids`, `committee.chairman_id`, `task.assignee_id`, `task.creator_id` and `event.confirmed_attendees` all hold a `chapter_membership.id` — never an `auth.uid`. Use `AuthViewModel.currentMembershipId` for anything stored on a chapter row; `currentUserId` is only for the person (profile, storage paths).
- **Cargo is not permission.** `role` is descriptive and changes every term. Authorization is `AccessLevel` (`member` < `admin` < `owner`), read through `PermissionSet.can(_:)` from `@Environment(\.permissions)`, injected once in `ContentView`.

`Member` is deliberately **not** the person — it is the roster projection the UI lists, decoded from the `chapter_roster` view.

**Owner is transferred, never promoted.** `set_membership_access_level` moves people between `member` and `admin` and explicitly refuses `owner` in either direction; `transfer_chapter_ownership` is the single path to that role and moves both rows in one statement. Both are owner-only and live in RPCs because `access_level` is never granted to `authenticated`.

**A chapter with no owner is bootstrapped by the platform, not by the chapter.** Every other door needs someone already inside, so the first person through sends a `join_request` with `kind = 'chapter_bootstrap'` and a proof image in the private `bootstrap-proof` bucket (path `{auth.uid()}/{uuid}.jpg`, which is what the Storage policies check). `is_platform_admin` reviews it through `pending_bootstrap_requests` — the one read in the app that deliberately spans chapters — and approval always grants `owner`. `chapter.has_owner` drives the fork in `ChapterSelectionView`, and both the insert policy and the approval refuse a chapter that already has one.

**Roster deletion is limited to entries nobody claimed.** `chapter_roster.has_account` says whether a membership has a `member_id`; only rows without one can be deleted (`cm_delete_admin`), because erasing a real person's bond would take their attendance, tasks and committees with it. Someone with an account leaves on their own through `leave_chapter`.

**Invite codes are the fast path in.** `chapter_invite` codes are generated by a column `DEFAULT` (the `code` column is never granted to `authenticated`), redeemed through the `redeem_chapter_invite` RPC, and always grant `member` — a code travelling through a WhatsApp group must never hand out administration. There is deliberately **no RLS policy** letting non-members read `chapter_invite`, so codes cannot be enumerated, and redemption is rate limited through `invite_attempt` because the whole model rests on the code being unguessable. `DeepLink` (`baluarte://invite/<code>`) is a custom URL scheme, not a Universal Link: there is no domain to host an AASA file, and the code is always typable by hand.

**Entering a chapter is reviewed, never self-service.** You create a `join_request`; an admin of that chapter approves through the `approve_join_request` RPC, which is what inserts the membership. `RootRoute` therefore has a `.pendingApproval` state between `.chapterSelection` and `.app` — without it someone who asked is stranded on the search screen with no explanation. Leaving goes through `leave_chapter`, which refuses the last owner so a chapter can never be orphaned. At approval time the app *suggests* `admin` for officer roles (MC, 1º/2º Conselheiro, Escrivão, Consultor) as a pre-selected picker value; it never assigns it.

**Chapter is a read-only registry**, not user content: public `SELECT`, no `INSERT`/`UPDATE`/`DELETE` for `authenticated`. A chapter that is missing is *requested* (`chapter_request`), never created from the app. The real key is `(uf, number)` — Brazilian chapter numbering is per state jurisdiction, so a globally unique number is wrong. Search goes through the `search_chapters` RPC so accents and case use the same `unaccent` index the registry is built on.

**Tasks are scoped to committees.** A committee task is visible and completable only to that committee's members (the chairman counts) and to chapter admins; a task with no committee is personal to its creator and assignee. This lives in RLS (`task_select` / `task_insert`), and `CreateTaskViewModel` only offers committees the person belongs to, because `task_insert` rejects the rest.

**Permissions are UX only.** `.requires(_:)` (removes the affordance) and `.gated(_:reason:)` (keeps it visible but inert) only decide what gets drawn. The anon key ships inside the binary, so every gated action must independently be denied by an RLS policy or by an RPC raising `42501`. Adding a gate without the matching policy is a security bug, not a partial implementation.

**When an operation needs an RPC**: only when the caller must legitimately touch rows they cannot see under RLS, or when a multi-row invariant must be atomic (e.g. `set_event_attendance` — a `with check` cannot inspect an array delta). Everything else stays plain PostgREST plus a policy. Authorization failures raise `42501` (→ 403); business rules raise `23514`.

**Server messages are translated by their hint, never by their text.** Postgres does not know the caller's language, so every `raise` that can reach a person carries a stable `hint = 'baluarte.<key>'` (optionally `:<argument>` for the one parameterized case), and `ServerMessage` maps that key to a localized string — the Portuguese message stays as the exception text for the log, for `curl` and for older app versions. `AppError.from` reads the hint **before** the code, so a `42501` or `P0002` that names a real reason shows it instead of the generic refusal, while a bare `insufficient_privilege` carries no hint and stays generic. Any other SQLSTATE returns `.serverError`: a constraint name or a PostgREST diagnostic is text written for a developer, and passing it through would put `duplicate key value violates unique constraint` on screen. A new `raise` therefore needs three things together — the hint in the migration, the case in `ServerMessage`, and the key in all three languages of `Localizable.xcstrings`; `AppErrorTests` fails if the second is missing.

**Column grants matter as much as RLS.** RLS is blind to columns: `access_level`, `approved_by` and `is_platform_admin` are never granted to `authenticated`, which is the only thing stopping self-promotion. Any service writing to `member` or `chapter_membership` must send a partial payload naming only granted columns — sending the whole `Codable` model gets a 403.

**Dependency injection**: services flow into ViewModels via protocol-typed initializer params (default = real impl); `AuthViewModel` itself is injected into Views via `@Environment`, not passed down manually.

**Navigation**: `NavigationStack` with value-based routes only — `NavigationView` is banned.

**Extensions beyond the main app target**: `Intents/` holds AppIntents (Siri Shortcuts, e.g. `ConfirmAttendanceIntent`, `NextEventIntent`) and `BaluarteWidgets/` is a separate WidgetKit extension target with its own data manager (`WidgetDataManager`) that talks to PostgREST over raw `URLSession`. It authenticates with the session token from the shared keychain and refreshes it itself when expired — there is deliberately **no anon-key fallback**, because under RLS an anonymous read returns `200 OK` with an empty array rather than an error, which would silently overwrite the widget's cache with nothing. Caches are keyed per chapter so a chapter switch cannot leak the previous chapter's data.

## Conventions (from `.agents/AGENTS.md`)

- No force unwrapping (`!`) anywhere — use `if let`/`guard let`/`??`.
- `async/await` for async work; `@MainActor` is required on ViewModel methods that mutate UI state.
- Break up large view `body`s into separate reusable structs (prefer this over `some View`-returning helper functions), placed in `DesignSystem/Components/` when generic.
- No inline `//` comments except `MARK:` in long files — code should be self-explanatory through naming.
- Optimistic UI updates for toggle/quick-update interactions (apply immediately, revert on API failure).
- UI/UX changes must account for Nielsen's heuristics, WCAG (contrast, 44x44pt touch targets, VoiceOver/Dynamic Type), and cognitive-load principles (Hick's Law, Von Restorff effect) — this is treated as mandatory, not optional polish.
- Unit tests cover ViewModels and Models only (business logic, data transforms, computed properties); Mocks under `BaluarteTests/Mocks/` must stay deterministic.
- Git commit messages must be written in English following Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`), even though chat/docs are in Portuguese (pt-BR).
- Native-first: exhaust native iOS/SwiftUI APIs (EventKit, Foundation Models, AppIntents, WidgetKit) before adding any third-party SPM dependency.
