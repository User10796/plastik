# Plastik

<p align="center">
  <img src="public/logo.svg" alt="Plastik Logo" width="120" height="120">
</p>

<p align="center">
  <strong>Credit Card Benefits & Rewards Tracker</strong>
</p>

<p align="center">
  A comprehensive tool for tracking credit card benefits, signup bonuses, spending caps, points balances, and churning strategy.
</p>

---

## Features

- 🃏 **Multi-Card Tracking** - Track unlimited cards with details for two players
- 🎯 **Signup Bonus Progress** - Visual progress bars for spending thresholds
- 📊 **Spending Cap Tracking** - Monitor category limits (e.g., 6% on groceries)
- 💎 **Points Management** - Consolidated view of all rewards currencies
- ✈️ **Companion Pass Tracking** - Southwest CP, Delta certificates, and more
- 📋 **Application History** - Log applications with status and credit limits
- 📈 **Hard Inquiry Tracking** - Optional credit report import
- 📚 **Issuer Velocity Rules** - Built-in database for Chase 5/24, Amex rules, etc.
- 📅 **Annual Fee Calendar** - Keep/downgrade/cancel decisions
- 💰 **Debt Payoff Strategy** - Snowball method calculator
- 🤖 **AI-Powered Analysis** - Claude API for statement parsing and recommendations

## Installation

### Prerequisites

- Node.js 18 or later
- npm or yarn
- macOS 10.15+ (for native app)

### Quick Start

```bash
# Clone the repository
git clone https://github.com/User10796/plastik.git
cd plastik

# Install dependencies
npm install

# Run in development mode
npm run dev

# In another terminal, start Electron
npm run electron
```

### Building for macOS

```bash
# Build the native macOS app
npm run build:mac

# The .dmg file will be in the dist/ folder
```

## Development

### Project Structure

```
plastik/
├── package.json          # Dependencies and scripts
├── vite.config.js        # Vite build configuration
├── index.html            # HTML entry point
├── electron/
│   ├── main.js          # Electron main process
│   └── preload.js       # Storage bridge for renderer
├── src/
│   ├── App.jsx          # Main React component (all app code)
│   └── main.jsx         # React entry point
└── public/
    └── logo.svg         # App icon
```

### Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Start Vite dev server |
| `npm run electron` | Start Electron (requires dev server) |
| `npm run electron:dev` | Start both Vite and Electron |
| `npm run build` | Build for web |
| `npm run build:mac` | Build macOS .dmg |

## API Integration

Plastik uses the Anthropic Claude API for:

1. **Statement Parsing** - Extract data from pasted statement text
2. **Card Analysis** - Personalized recommendations for new cards
3. **Credit Report Import** - Parse hard inquiry sections

### Setting Up Your API Key

1. Get an API key from [console.anthropic.com](https://console.anthropic.com)
2. Click "API Not Set" in the app header
3. Enter your API key and save

The app uses Claude Sonnet for cost-effective parsing. Typical usage costs pennies per month.

## Data Storage

All data is stored locally:
- **Web mode**: Browser's persistent storage API
- **Desktop mode**: Electron's user data folder

Data is not synced to the cloud. Your API key is stored securely on your device.

## License

MIT

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
