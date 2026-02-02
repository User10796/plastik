# Plastik — Build & Test Next Steps

## iOS App (TestFlight)

### 1. Register Bundle IDs

In the [Apple Developer portal](https://developer.apple.com/account/resources/identifiers/list):

1. Register **App ID**: `com.plastikapp.ios` with CloudKit capability
2. Register **App ID**: `com.plastikapp.ios.widget` for the widget extension
3. Create a **CloudKit Container**: `iCloud.com.plastikapp.ios`
4. Create an **App Group**: `group.com.plastikapp.ios`

### 2. Create App in App Store Connect

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **My Apps → + → New App**
3. Name: **Plastik**
4. Bundle ID: **com.plastikapp.ios**
5. SKU: `plastik-001`

### 3. Archive & Upload

1. Open `plastik-ios/Plastik.xcodeproj` in Xcode
2. Select **Plastik** scheme, destination **Any iOS Device (arm64)**
3. Signing should be automatic with your team
4. **Product → Archive**
5. Click **Distribute App → App Store Connect → Upload**

### 4. TestFlight

1. In App Store Connect, go to the **TestFlight** tab
2. Build appears after processing (~5-15 min)
3. Add **internal testers**
4. Install via TestFlight notification on your iPhone

## macOS App

### Building for macOS

1. Open `plastik-ios/Plastik.xcodeproj` in Xcode
2. Select **PlastikMac** scheme
3. Choose **My Mac** as destination
4. Press ⌘R to build and run

### Quick Local Testing (iOS Simulator)

Open `Plastik.xcodeproj` in Xcode and hit ⌘R with the simulator selected.

Or via CLI:

```bash
cd ~/Downloads/Plastik/plastik-ios
xcodegen generate
xcodebuild \
  -project Plastik.xcodeproj \
  -scheme Plastik \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  build
```
