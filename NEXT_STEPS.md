# Plastik — Build & Test Next Steps

## macOS DMG (Electron App)

```bash
cd /Users/sterling/Downloads/plastik
npm install
npm run build:mac
```

The `.dmg` will appear in the `dist/` folder. Open it and drag Plastik to Applications.

## iOS App (TestFlight)

### 1. Register Bundle IDs

In the [Apple Developer portal](https://developer.apple.com/account/resources/identifiers/list):

1. Register **App ID**: `com.plastikapp.ios` with CloudKit capability
2. Register **App ID**: `com.plastikapp.ios.widget` for the widget extension
3. Create a **CloudKit Container**: `iCloud.com.plastikapp.ios`

### 2. Create App in App Store Connect

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **My Apps → + → New App**
3. Name: **Plastik**
4. Bundle ID: **com.plastikapp.ios**
5. SKU: `plastik-001`

### 3. Archive & Upload

1. Open `cardflow-ios/Plastik.xcodeproj` in Xcode
2. Select **Plastik** scheme, destination **Any iOS Device (arm64)**
3. Signing should be automatic with team JLV37S2CYD
4. **Product → Archive**
5. Click **Distribute App → App Store Connect → Upload**

### 4. TestFlight

1. In App Store Connect, go to the **TestFlight** tab
2. Build appears after processing (~5-15 min)
3. Add **internal testers**
4. Install via TestFlight notification on your iPhone

### Quick Local Testing (Simulator)

Open `Plastik.xcodeproj` in Xcode and hit ⌘R with the simulator selected.

Or via CLI:

```bash
cd /Users/sterling/Downloads/plastik/cardflow-ios
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Plastik.xcodeproj \
  -scheme Plastik \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  build

open -a Simulator
xcrun simctl boot "iPhone 16" 2>/dev/null
xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/Plastik-*/Build/Products/Debug-iphonesimulator/Plastik.app
xcrun simctl launch booted com.plastikapp.ios
```
