# Plastik

<p align="center">
  <strong>Credit Card Rewards & Benefits Tracker</strong>
</p>

<p align="center">
  A native iOS and macOS app for tracking credit card rewards, signup bonuses, and churning strategy.
</p>

---

## Features

- 🃏 **Card Portfolio** - Track all your credit cards with issuer details and annual fees
- 🎯 **Signup Bonus Tracking** - Visual progress bars for meeting minimum spend requirements
- 📊 **Best Card Recommendations** - See which card to use for each spending category
- 💎 **Points & Miles** - Track balances across all rewards currencies
- 🔄 **iCloud Sync** - Seamless sync between iPhone, iPad, and Mac via CloudKit
- 📱 **iOS Widget** - Quick glance at your best card recommendations
- 📋 **5/24 Tracking** - Monitor your Chase 5/24 status
- 🔒 **Close/Reopen Cards** - Track closed cards and rechurn eligibility
- 🔔 **Notifications** - Reminders for bonus deadlines and annual fee dates

## Platforms

| Platform | Requirements |
|----------|--------------|
| **iOS** | iPhone/iPad running iOS 17.0+ |
| **macOS** | Mac running macOS 14.0+ |

## Installation

### Requirements

- Xcode 15.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for generating the Xcode project)

### Setup

```bash
# Clone the repository
git clone https://github.com/User10796/plastik.git
cd Plastik/plastik-ios

# Generate Xcode project
xcodegen generate

# Open in Xcode
open Plastik.xcodeproj
```

### Building

**For iOS:**
1. Select the `Plastik` scheme
2. Choose your iOS device or simulator
3. Press ⌘R to build and run

**For macOS:**
1. Select the `PlastikMac` scheme
2. Choose "My Mac" as the destination
3. Press ⌘R to build and run

## Project Structure

```
Plastik/
├── plastik-ios/              # Native Swift/SwiftUI app
│   ├── Plastik/
│   │   ├── App/              # App entry point and main views
│   │   ├── Models/           # Data models (CreditCard, UserCard, etc.)
│   │   ├── Views/            # SwiftUI views organized by feature
│   │   ├── ViewModels/       # Observable view models
│   │   ├── Services/         # CloudKit, DataFeed, Notifications
│   │   ├── Utilities/        # Constants, Extensions
│   │   └── Resources/        # Assets, bundled card data
│   ├── PlastikWidget/        # iOS Home Screen widget
│   └── project.yml           # XcodeGen configuration
└── README.md
```

## Data & Sync

- **Local Storage**: Card data stored in UserDefaults with App Group sharing
- **iCloud Sync**: CloudKit private database for cross-device sync
- **Card Catalog**: Fetched from [plastik-data](https://user10796.github.io/plastik-data/cards.json) with bundled fallback
- **Widget**: Shares data via App Group container

## Configuration

### App Group
```
group.com.plastikapp.ios
```

### iCloud Container
```
iCloud.com.plastikapp.ios
```

### Bundle IDs
- iOS App: `com.plastikapp.ios`
- macOS App: `com.plastikapp.ios`
- Widget: `com.plastikapp.ios.widget`

## License

MIT

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
