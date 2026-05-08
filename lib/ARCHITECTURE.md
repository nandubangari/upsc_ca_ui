# Project Architecture Documentation

This document describes the refactored architecture of the `upsc_ca_ui` project.

## Folder Structure

```text
lib/
 ├── core/
 │    ├── config/         # App constants and configuration
 │    ├── theme/          # App theme definitions
 │    ├── utils/          # Utility classes (DateFormatter, AppLogger)
 │
 ├── data/
 │    ├── parsers/        # Source-specific HTML parsers and extractors
 │    │    ├── generic/
 │    │    ├── insightsias/
 │    │    ├── nextias/
 │    │    ├── vajiram/
 │    │    ├── visionias/
 │    │    ├── article_parser.dart # Central parser entry point
 │    │
 │    ├── repositories/   # Centralized data access layer
 │    │    ├── auth_repository.dart
 │    │    ├── dashboard_repository.dart
 │    │
 │    ├── services/       # Raw data fetching services (Firestore, HTTP)
 │    │
 │    ├── sync/           # Synchronization logic between remote and local/firestore
 │
 ├── shared/
 │    ├── models/         # Centralized data models
 │    ├── widgets/        # Reusable UI components
 │
 ├── features/           # Feature-specific screens and logic
 │    ├── auth/
 │    ├── home/
 │    ├── profile/
 │    ├── reader/
 │    ├── web_view/
 │
 ├── providers/          # Global state management providers
 ├── main.dart           # App entry point
```

## Data Flow

1.  **UI Layer**: Features screens (in `features/`) use `Providers` (in `providers/`) to access state and trigger actions.
2.  **State Management**: `Providers` use `Repositories` (in `data/repositories/`) to fetch or update data.
3.  **Repository Layer**: `Repositories` orchestrate data flow between `Services` and `Sync Services`.
4.  **Sync layer**: `Sync Services` (in `data/sync/`) handle the logic of checking Firestore vs fetching from remote sources via `Services`.
5.  **Service Layer**: `Services` (in `data/services/`) handle raw networking or Firestore calls.
6.  **Parsing Layer**: `ArticleParser` (in `data/parsers/`) uses source-specific extractors to transform raw HTML into `ArticleContent` models.

## Key Models

- **ArticleModel**: Standardized model for articles across all sources.
- **QuizModel**: Standardized model for quizzes across all sources.
- **DashboardTask**: Represents a daily task containing articles and quizzes.
- **DashboardData**: Top-level model for the dashboard state.

## Naming Conventions

- **Models**: Suffix with `Model` if needed for clarity (e.g., `ArticleModel`).
- **Repositories**: Suffix with `Repository`.
- **Services**: Suffix with `Service`.
- **Sync Services**: Suffix with `SyncService`.
- **Screens**: Suffix with `Screen`.
- **Widgets**: Descriptive names, PascalCase.
