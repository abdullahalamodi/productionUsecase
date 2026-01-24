# Flutter Web: Reliable Updates Strategy (No Caching) (firebase hosting)

This guide implements a strategy to force Flutter Web updates immediately by disabling the Service Worker, enforcing no-cache headers on the server, and polling for a version file to notify users of new deployments.

---

## 1. Configure Firebase Headers (`firebase.json`)

We must tell the browser/CDN never to cache the entry point (`index.html`) or the version file.

Update your `firebase.json`:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "headers": [
      {
        "source": "/index.html",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "no-cache, no-store, must-revalidate"
          }
        ]
      },
      {
        "source": "/version.json",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "no-cache, no-store, must-revalidate"
          }
        ]
      },
      {
        "source": "**/*.@(css|png|jpg|jpeg|gif|webp|svg|wasm)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=604800"
          }
        ]
      }
    ]
  }
}
```

---

## 2.1 Automate Build & Versioning (`deploy.sh`) (to test local)

This script extracts the version from `pubspec.yaml`, builds the app without the PWA service worker, and generates the `version.json` file that the app will check against.

**File:** `deploy.sh`

```bash
#!/bin/bash

# 1. Extract version from pubspec.yaml (e.g., 1.0.0+1)
FULL_VERSION=$(cat pubspec.yaml | grep version: | cut -d ' ' -f 2)
VERSION=$(echo $FULL_VERSION | cut -d '+' -f 1)
BUILD_NUMBER=$(echo $FULL_VERSION | cut -d '+' -f 2)

echo "🚀 Building version: $FULL_VERSION (V:$VERSION B:$BUILD_NUMBER)..."

# 2. Clean previous build
rm -rf ./build/web

# 3. Build Web
# --pwa-strategy=none: Disables Service Worker generation to prevent caching issues
# --dart-define=APP_VERSION: Passes version to Dart code for local comparison
flutter build web --release \
  --dart-define-from-file=assets/config/dev.json \
  --dart-define=APP_VERSION="$FULL_VERSION" \
  --pwa-strategy=none

# 4. Generate version.json in the build folder
# This file is what the running app checks to see if an update exists.
echo "{\"version\": \"$VERSION\", \"build_number\": \"$BUILD_NUMBER\"}" > build/web/version.json

echo "✅ Build complete. version.json created."

# 5. Deploy to Firebase (Uncomment to use)
# firebase deploy --only hosting
```

**How to run:**

```bash
chmod +x deploy.sh
./deploy.sh
```

---
## 2.2 Automate Build & Versioning (`deploy-prod.yml`) (github actions)
Add this file to gethub actions and it will deploy on push on main branch it do the same what `deploy.sh` do.
I'm using env variables from config file so you need to add `PROD_CONFIG` secret 
and  `FIREBASE_SERVICE_ACCOUNT` for firebase auth
here for build_number we're using `github.run_number` from github 

**File:** `deploy-prod.yml`
```
name: Deploy to Firebase Hosting (production)

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.3' # or 'stable'
          channel: 'stable'

      - name: Create prod.json from secret
        run: |
          mkdir -p assets/config
          echo '${{ secrets.PROD_CONFIG }}' > assets/config/prod.json

      - name: Get dependencies
        run: flutter pub get

      - name: Generate internationalization files
        run: dart run intl_utils:generate

      - name: Build_runner build
        run: dart run build_runner build -d

      - name: Extract version from pubspec.yaml
        id: version
        run: |
          VERSION=$(cat pubspec.yaml | grep '^version:' | cut -d ' ' -f 2 | cut -d '+' -f 1)
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "Version : $VERSION"
          echo "Build Number : ${{ github.run_number }}"

      - name: Build Flutter Web
        run: |
          flutter build web --release \
            --dart-define-from-file=assets/config/prod.json \
            --dart-define=APP_VERSION="${{ steps.version.outputs.version }}+${{ github.run_number }}" \
            --pwa-strategy=none

      - name: Generate version.json
        run: |
          echo "{\"version\": \"${{ steps.version.outputs.version }}\", \"build_number\": \"${{ github.run_number }}\"}" > build/web/version.json

      - name: Deploy to Firebase
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: [YOUR_PROJECT_ID]
```

---

## 3. Version State Logic (`checkAppVersionProvider`)

This provider checks `version.json` every hour and compares it with the current app version.

**File:** `check_app_version_provider.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// Define your current app version constant if not already global
// You can also read this from the --dart-define we set in the script
const kAppVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0+1');

typedef _MainState = String?;

final checkAppVersionProvider =
    StateNotifierProvider<CheckAppVersionProvider, _MainState>((ref) {
  return CheckAppVersionProvider(ref);
});

class CheckAppVersionProvider extends StateNotifier<_MainState> {
  final Ref ref;
  Timer? _hourlyTimer;

  CheckAppVersionProvider(this.ref) : super(null) {
    init();
  }

  Future<void> init() async {
    // Check immediately on load, then start timer
    await _remoteChecker();
    _hourlyAppVersionTimer();
  }

  // Remote check every hour
  void _hourlyAppVersionTimer() {
    _hourlyTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      await _remoteChecker();
    });
  }

  Future<void> _remoteChecker() async {
    try {
      // Add timestamp to query param to bypass browser cache
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Using relative path so it adapts to base href automatically
      final url = Uri.parse('version.json?t=$timestamp');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final version = json['version'];
        final buildNumber = json['build_number'];
        final remoteVersion = '$version+$buildNumber';

        // Update state only if versions differ
        if (remoteVersion != kAppVersion) {
           state = remoteVersion;
           log('Update detected: Local: $kAppVersion vs Remote: $remoteVersion');
        }
      }
    } catch (e) {
      log('Error checking version: $e');
    }
  }

  @override
  void dispose() {
    _hourlyTimer?.cancel();
    super.dispose();
  }
}
```

---

## 4. UI Notification Banner (`AppVersionUpdateBanner`)

A banner that appears only when state (the new version string) is not null.

**File:** `app_version_update_banner.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

// import '../../../generated/l10n.dart'; // Adjust path
// import '../../core.dart'; // Adjust path

class AppVersionUpdateBanner extends ConsumerWidget {
  const AppVersionUpdateBanner({super.key});

  void _updateApp() {
    // Forces a browser reload. 
    // Since we used --pwa-strategy=none and no-cache headers, 
    // this guarantees loading the new version.
    web.window.location.reload();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newVersion = ref.watch(checkAppVersionProvider);

    // If no new version is detected, hide the widget completely
    if (newVersion == null) {
      return const SizedBox.shrink();
    }

    const style = TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w500
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.blue, // Replace with your primary500 color
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.system_update, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            'New Update Available (v$newVersion)', // Use S.of(context) here
            style: style,
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: _updateApp,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(4)
              ),
              child: Text(
                'REFRESH', // Use S.of(context).updateNow here
                style: style.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 5. Implementation

Place the banner at the top of your main layout (e.g., inside your `MaterialApp` builder or your main `Scaffold`).

```dart
// inside your Main Layout or Home Screen
Column(
  children: [
    const AppVersionUpdateBanner(), // Will be size 0 if no update
    Expanded(child: Navigator(...)), // Your main app content
  ],
)
```

---

## Summary

This strategy ensures:

- ✅ No Service Worker caching issues
- ✅ Immediate update detection every hour
- ✅ User-friendly update notification banner
- ✅ One-click refresh to load new version
- ✅ Automated versioning in deployment script
