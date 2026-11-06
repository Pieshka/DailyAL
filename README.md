<div align="center">

<a href="https://dailyanimelist.web.app/">
  <img src="assets/images/dal-black-bg.png" alt="DailyAL" title="DailyAL" width="88"/>
</a>

# DailyAnimeList (DailyAL)

**An unofficial Flutter client for MyAnimeList (MAL), with fork-specific Ameo recommendations and improvements to search, list synchronization, notifications, and diagnostics.**

[![Discord](https://img.shields.io/discord/1147503264741478452.svg?label=Discord&logo=discord&logoColor=white)](https://discord.gg/ap4Wghv5e8)
[![Upstream Releases](https://img.shields.io/github/v/tag/JICA98/DailyAL?label=Upstream%20version&logo=github)](https://github.com/JICA98/DailyAL/releases)
[![License](https://img.shields.io/github/license/JICA98/DailyAL)](LICENSE)

</div>

> **About this repository:** This is a community fork of [onemind66/DailyAL](https://github.com/onemind66/DailyAL). It retains DailyAL's core MAL client functionality and adds fork-specific features and fixes. The upstream release and download links below refer to the original project, not a separate release published by this fork.

## Contents

- [Overview](#overview)
- [Features](#features)
- [Fork-specific improvements](#fork-specific-improvements)
- [Screenshots](#screenshots)
- [Download and build](#download-and-build)
- [Development setup](#development-setup)
- [Repository layout](#repository-layout)
- [Notes and limitations](#notes-and-limitations)
- [Credits and license](#credits-and-license)

## Overview

DailyAL is a Flutter-based client for exploring anime and manga from MyAnimeList. It brings catalog discovery, search, personal-list management, community content, and user customization into one application.

This fork also includes **Ameo**, an optional anime recommendation integration, a replacement for the offline public Jikan API, and reliability and usability improvements in notifications, search results, MAL list-status synchronization, and character/person detail loading.

## Features

### Anime and manga discovery

- Browse seasonal, airing, upcoming, popular, and ranked anime and manga.
- View title details, synopsis, statistics, genres, related titles, and recommendations.
- Read anime reviews and explore MyAnimeList community forums.
- Browse character and person information, including related images and voice-acting information where provided by the data service.

### Search and filtering

- Search across supported content categories, including anime, manga, characters, people, forums, clubs, featured content, and news.
- Use DailyAL's special search shortcuts, including `@` and `#` queries.
- Filter and sort results using the available category-specific controls.
- View available MyAnimeList list status, score, and progress information on supported anime and manga results.
- Receive clearer error feedback when external search services fail instead of having every failure appear as an ordinary empty result.

### Personal anime and manga lists

- View and update your personal MyAnimeList entries.
- Edit supported list fields, scores, and progress.
- Sort list entries using supported criteria such as title, score, start date, and update date.
- Keep cached list data and status updates synchronized across supported search and recommendation surfaces.

### Ameo anime recommendations

This fork integrates the external **Ameo/Sprout** recommendation service into DailyAL.

- Add the Ameo recommendation section through the customizable Home Page item settings.
- Open the dedicated recommendation screen and configure the supported recommendation options.
- Resolve the MyAnimeList profile from the signed-in account when possible, or configure a username where supported.
- Browse recommendations using DailyAL's familiar anime cards and open matching titles in the app.
- View prediction metadata and expandable recommendation explanations when the service returns them.
- Choose among the model identifiers supported by the integration: `2026-logq`, `2026-rc`, `2025-jax`, and `legacy`.
- Cache recommendation responses for a limited period and use usable cached results when a refresh fails.
- Refresh list-status information so recommendation cards can reflect relevant changes to your MAL list.

Ameo is an optional integration. Recommendations depend on the external service, a usable username/profile, network access, and the data returned by that service. Prediction values and explanations may be absent for some results.

### Anime release notifications

- Configure reminders for anime on your **Watching** list and notifications related to titles on **Plan to Watch**, according to the available notification preferences.
- Synchronize reminders against the user's MyAnimeList list and the schedule data available from the app's services.
- Refresh notification state during relevant preference changes and when the app resumes.
- Request notification and exact-alarm permissions independently where the platform requires them.
- Use the built-in test notification to check whether the app can schedule a notification.

Reminder scheduling is best-effort and depends on permissions, network responses, and schedule data. The app avoids treating an incomplete or failed list response as proof that the user's list is empty, helping prevent valid reminders from being removed accidentally.

### Themes and customization

- Choose from four seasonal dark themes: Spring, Summer, Fall, and Winter.
- Customize supported navigation and Home Page content.
- Adjust cache-related preferences and other available user settings.
- Configure the preferred title language and other presentation preferences where available.

## Fork-specific improvements

In addition to Ameo, this fork contains maintenance and reliability work across several parts of the application.

| Area | Improvements |
|---|---|
| MAL authentication and requests | Improved token-refresh handling and request behavior, including retry/error paths. |
| List-status synchronization | Preserve successful list edits as per-title snapshots and merge fresh status information into supported search and recommendation results. |
| Search | Improved pagination and result-field handling, producer filtering, retry behavior for Jikan requests, and error messages for failed searches. |
| Character and person details | Validate detail responses, retry unusable cached data, and provide an error state with selectable/copyable diagnostic information when loading fails. |
| Notifications | Use one-shot release reminders, reconcile against the user's relevant MAL lists, refresh when appropriate, and preserve existing reminders when list or schedule data is incomplete. |
| Android layouts | Improve safe-area and system-navigation insets for search filters and settings sheets to reduce controls being hidden behind system UI. |
| Profile and statistics | Improve list/profile data parsing and handling of chart data used by profile insights. |
| Logging | Add opt-in timestamped file logging and more structured diagnostics for investigating API and detail-loading failures. |
| Build workflow | Keep a manually triggered GitHub Actions workflow for producing an Android release APK artifact. |
| Jikan-compatible data service | Replace the offline public Jikan API with a configurable Jikan-compatible service (jikan-edge by default). Requests, models, and parsers accept both Jikan v4 (`snake_case`, bare payloads) and jikan-edge (`camelCase`, `{ data, meta }`) responses, and query parameters the replacement rejects are dropped instead of failing the request. |
| API endpoint settings | Add a settings screen for overriding the Jikan, DAL API, and app-config URLs at runtime, with URL validation, persistence across restarts, and a reset to the bundled defaults. |
| Magazines and user history | Select the magazines block by the links it contains rather than its position on the page, and request anime and manga history together so the history page shows both media types. |
| Airing schedule and countdown | Scope schedule parsing to the schedule table, accept the date formats MyAnimeList currently outputs, and fall back to the data service's airing fields. The schedule screen also loads the same lists used for notification scheduling and refreshes when that data changes, so titles that already produce reminders appear there. |
| Notification management | Add a reset action and a list of queued reminders in the notification settings, so scheduled reminders and their artwork can be inspected and rebuilt without reinstalling the app. |
| Android insets in full-screen views | Keep fixed-position controls — the anime graph toolbar, profile statistics search field, image preview, video seek bar, clubs search field, and intro skip button — above the system navigation bar. |
| Profile statistics cards | Stop score values and status badges from being clipped in the "I liked it, they hated it" cards, and give the section enough height for the taller cards. |
| Friend profiles and profile backgrounds | Show a retry state when a friend lookup fails, keep the drag pill centered on both own and friend profiles, and treat a missing numeric MAL id as "no background" instead of throwing. |
| List pages and recent items | Let the system back button close an active search field before leaving the page, remove the intended entry when clearing recent anime or manga, and optionally include search history and recent items in backups. |
| Review summaries | Gate the AI-generated review summary behind a local preference in addition to the remote feature flag, so the request can be turned off when the hosted service is unavailable or unwanted. |
| Failure handling | Keep failed futures from leaving loading widgets stuck on the spinner, and skip unusable entries (missing dates, mismatched content types, unavailable profile data) instead of blanking an entire list row. |
| Localization | Add the missing strings across the bundled locales and keep their key sets aligned, including strings that were previously hardcoded in Indonesian, such as the Ameo section title and the diagnostic-log save button. |
| Tests | Add regression tests for HTML and API parsing, endpoint configuration, notification scheduling, recent-item handling, localization parity, and widget layout. |

These are code-level improvements; they do not imply that every external API or platform has been tested in every environment. See [Notes and limitations](#notes-and-limitations).

> **Jikan-compatible service:** The default replacement for `api.jikan.moe` is a third-party deployment, not an official MyAnimeList or Jikan endpoint. Its base URL can be changed from **Settings → API Endpoints** or with the `JIKAN_BASE_URL` environment variable, and the bundled DAL handlers use the same base URL.

## Screenshots

The images below are the screenshots already included in the repository's English metadata.

<div style="overflow-x: auto; white-space: nowrap;">
  <img src="metadata/en-US/images/phoneScreenshots/Screenshot_1.png" alt="DailyAL screenshot 1" width="200"/>
  <img src="metadata/en-US/images/phoneScreenshots/Screenshot_2.png" alt="DailyAL screenshot 2" width="200"/>
  <img src="metadata/en-US/images/phoneScreenshots/Screenshot_3.png" alt="DailyAL screenshot 3" width="200"/>
  <img src="metadata/en-US/images/phoneScreenshots/Screenshot_4.png" alt="DailyAL screenshot 4" width="200"/>
  <img src="metadata/en-US/images/phoneScreenshots/Screenshot_5.png" alt="DailyAL screenshot 5" width="200"/>
  <img src="metadata/en-US/images/phoneScreenshots/Screenshot_6.png" alt="DailyAL screenshot 6" width="200"/>
  <img src="metadata/en-US/images/phoneScreenshots/Screenshot_7.png" alt="DailyAL screenshot 7" width="200"/>
  <img src="metadata/en-US/images/phoneScreenshots/Screenshot_8.png" alt="DailyAL screenshot 8" width="200"/>
</div>

## Download and build

### Download

For currently published upstream builds, check:

- [JICA98/DailyAL releases](https://github.com/JICA98/DailyAL/releases)
- [F-Droid package](https://f-droid.org/packages/io.github.jica98/)

Those distribution pages belong to the upstream project. This fork's repository currently includes a manually triggered GitHub Actions workflow for building an Android release APK; it does not, by itself, mean that a fork-specific release has been published.

### Build an Android APK with GitHub Actions

1. Open the repository's **Actions** tab.
2. Select **Build Android APK (Manual)**.
3. Choose **Run workflow** on the branch you want to build.
4. After the workflow completes, download the `DailyAL-Android-APK` artifact from that run.

The workflow installs Java 17, configures the stable Flutter channel, runs `flutter pub get`, and builds with `flutter build apk --release`.

### Build locally

The application is built with Flutter. See the setup instructions below to prepare a development environment.

## Development setup

### Requirements

- [Git](https://git-scm.com/downloads).
- [Flutter SDK](https://docs.flutter.dev/get-started/install) on the stable channel.
- A compatible Dart SDK. The root `pubspec.yaml` specifies Dart `>=3.2.6 <4.0.0`.
- An Android SDK and configured Android device/emulator for Android development.
- A configured desktop toolchain if you intend to target a desktop platform.

### Clone and install dependencies

```bash
git clone https://github.com/onemind66/DailyAL.git
cd DailyAL
flutter pub get
```

Run the app on a configured device or target:

```bash
flutter run
```

You can also open `dal-code.code-workspace` in Visual Studio Code and launch the `dailyanimelist` configuration with **F5**, if you use the repository's workspace tasks.

### Generated files and translations

When changing localization sources or generated models, use the repository's configured development tasks where possible. The corresponding commands include:

```bash
dart run intl_utils:generate
dart run build_runner build --delete-conflicting-outputs
python3 python/init.py
```

These commands are for regeneration/development workflows, not required for every normal app launch. Check the VS Code tasks and source scripts before running them; translation processing may have additional requirements.

### Tests

The repository contains Flutter tests under `test/` and Dart tests for the shared API package under `dal-api/dal_commons/test/`:

```bash
flutter test
cd dal-api/dal_commons && dart test
```

The Flutter tests run without a device or network access; widgets that would otherwise call the network are exercised against stubbed responses. Behavior that depends on the platform — system-navigation insets, notification delivery, and Android's back button — still has to be confirmed on a real device.

### Optional diagnostics

The fork includes timestamped file logging intended to help investigate issues. Logging and diagnostic output can contain technical request context, so review it before sharing publicly and never include access tokens, credentials, or other secrets in issue reports.

## Repository layout

| Path | Purpose |
|---|---|
| `lib/` | Main Flutter application, screens, widgets, preferences, and services |
| `lib/features/ameo/` | Ameo recommendation integration and UI |
| `lib/api/` | MyAnimeList and DailyAL API clients, authentication, and data handling |
| `lib/api/api_endpoint_settings.dart` | Runtime overrides for the Jikan, DAL API, and app-config URLs |
| `lib/notifservice.dart` | Anime release notification scheduling and reconciliation |
| `lib/util/file_logger.dart` | Optional timestamped diagnostic file logging |
| `dal-api/` | Dart API package and shared data models |
| `dal-api/dal_commons/test/` | Dart tests for the shared models and MyAnimeList HTML parsers |
| `dal-rust-api/` | Rust API/service component included in the repository |
| `assets/` | Application images, fonts, and other bundled assets |
| `metadata/` | Store metadata and screenshots |
| `test/` | Flutter tests for widgets, services, and localization |
| `.github/workflows/` | GitHub Actions workflows, including the manual Android APK build |

## Notes and limitations

- **MyAnimeList and third-party services:** Search, list updates, schedule data, character/person details, and Ameo recommendations depend on external services and network availability.
- **Jikan-compatible service:** The replacement for `api.jikan.moe` is a third-party deployment. It is not an official MyAnimeList or Jikan endpoint, its availability is not controlled by this repository, and it does not expose every field the original service provided — notably the numeric MyAnimeList id of a user. Point **Settings → API Endpoints** or `JIKAN_BASE_URL` at another deployment if needed.
- **Hosted features that are currently unavailable upstream:** Profile background images depend on a hosted storage service that currently returns server errors, and the replacement data service does not provide the numeric user id those backgrounds are matched with. The AI-generated review summary depends on a hosted summary service that currently fails; it is disabled by a local preference until that service is replaced.
- **Notifications:** Delivery depends on OS permissions, battery/background restrictions, alarm behavior, and the availability of valid schedule data. Use the in-app test notification when diagnosing setup issues.
- **Ameo:** It is a fork-specific integration, not a built-in MyAnimeList feature. Its results, models, prediction metadata, and explanations are controlled by the external service.
- **Build verification:** The existence of a build workflow documents the configured build path; it is not a guarantee that every commit has passed a full device test on every supported platform.
- **Platform support:** Flutter dependencies and platform folders alone do not guarantee a fully tested release for each platform. Validate the target platform's toolchain and native dependencies before distributing a build.
- **Privacy and diagnostics:** Do not publish OAuth tokens, credentials, or private account data. Inspect diagnostic logs before sharing them.
- **Upstream-only functionality:** This README documents capabilities visible in this fork's code and configuration. Do not assume that features available only in the upstream repository or its release builds are integrated here.

## Credits and license

DailyAL is based on the work of [JICA98 and contributors](https://github.com/JICA98/DailyAL). Please consult the repository's [LICENSE](LICENSE) and upstream project for license terms and attribution details.

Fork-specific additions are maintained in this repository. If you redistribute a build, make its origin clear and comply with the applicable license and third-party service terms.
