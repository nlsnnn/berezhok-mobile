# Berezhok Mobile — Agent Guidelines

Berezhok is a geolocation food sharing platform built with Flutter/Dart.

## Tech Stack

- **Framework**: Flutter (Dart SDK ^3.10.4)
- **State management**: Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- **Routing**: `go_router`
- **Networking**: Dio
- **Local storage**: `flutter_secure_storage`, `shared_preferences`
- **Maps**: `flutter_map`, `latlong2`
- **Location**: `geolocator`, `permission_handler`
- **Code generation**: `riverpod_generator`, `build_runner`

## Build / Lint / Test Commands

```bash
# Run the app
flutter run

# Run on specific device
flutter run -d chrome       # Web
flutter run -d macos         # macOS

# Analyze (lint)
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Run a single test by name
flutter test --name "should display user profile"

# Generate code (Riverpod providers, etc.)
dart run build_runner build

# Watch mode for code generation
dart run build_runner watch

# Clean and rebuild
flutter clean && flutter pub get

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart                  # Entry point, ProviderScope setup
├── app.dart                   # MaterialApp.router with theme
├── core/
│   ├── api/                   # ApiClient, exceptions, interceptors
│   ├── constants/             # App-wide constants
│   ├── router/                # GoRouter config, route constants
│   ├── theme/                 # Colors, typography, spacing
│   ├── utils/                 # Validators, formatters
│   └── widgets/               # Shared widgets (AppButton, AppTextField, etc.)
└── features/
    └── {feature}/
        ├── data/repositories/ # Abstract repo interface + mock/api impl
        ├── domain/            # Domain models (User, FoodLocation, etc.)
        ├── presentation/
        │   ├── pages/         # Screen widgets
        │   └── widgets/       # Feature-specific widgets
        └── providers/         # Riverpod providers and notifiers
```

## Code Style

### Imports

- Package imports first, then relative imports
- Separate groups with blank line

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/features/auth/providers/auth_providers.dart';
```

### Naming

- **Files**: `snake_case.dart` (e.g., `phone_input_page.dart`)
- **Classes**: `PascalCase` (e.g., `PhoneInputPage`, `FoodLocation`)
- **Variables/methods**: `camelCase`
- **Private members**: prefix with `_` (e.g., `_isSending`, `_dio`)
- **Constants**: `static const` in classes or top-level `const`
- **Routes**: `abstract final class AppRoutes` with static string constants

### Widgets

- Use `const` constructors where possible; always use `super.key`
- Stateless: extend `ConsumerWidget`; Stateful: extend `ConsumerStatefulWidget`
- Shared widgets go in `core/widgets/` with `App` prefix (`AppButton`, `AppTextField`)
- Feature widgets go in `features/{feature}/presentation/widgets/`

### Domain Models

- Plain Dart classes with `const` constructor
- Include `fromJson` factory, `toJson` method, `copyWith`, `toString`, `==`/`hashCode`
- Use `snake_case` keys in JSON

```dart
class User {
  final String id;
  final String name;
  // ...
  factory User.fromJson(Map<String, dynamic> json) => ...
  Map<String, dynamic> toJson() => ...
  User copyWith({String? name}) => ...
}
```

### Repositories

- Abstract class defines the contract
- Mock implementation for dev (`MockAuthRepository`)
- API implementation for production (`ApiAuthRepository`)
- Providers return the abstract type

### State Management (Riverpod)

- Use `AsyncNotifierProvider` for async state with loading/error/data
- Repository providers: `final authRepositoryProvider = Provider<AuthRepository>(...)`
- Convenience providers for derived state: `final isLoggedInProvider = Provider<bool>(...)`
- Use `ref.read()` for one-time reads, `ref.watch()` for reactive rebuilds

### Error Handling

- Typed exception hierarchy in `core/api/api_exceptions.dart`
- `ApiException` base class with specific subclasses: `UnauthorizedException`, `ValidationException`, `NotFoundException`, `ServerException`, `NetworkException`
- Use `AsyncValue.guard()` for safe async state updates
- Always check `mounted` before using `context` after async gaps

### Theme / Design Tokens

- Colors: `AppColors.primary`, `AppColors.textSecondary`, etc.
- Typography: `AppTypography.heading1`, `AppTypography.body1`
- Spacing: `AppSpacing.sm`, `AppSpacing.lg`, `AppSpacing.screenPadding`
- Use `switch` expressions for variant-based styling

### Dart 3 Features

- Use `switch` expressions instead of `if-else` chains for pattern matching
- Use `abstract final class` for non-instantiable utility classes
- Use `sealed class` for closed type hierarchies when appropriate

## Testing

- Framework: `flutter_test`
- Test files in `test/` directory, named `test_{feature}.dart`
- Tests are currently minimal — add tests when modifying existing features
- Use `WidgetTester` for widget tests, mock repositories for unit tests
