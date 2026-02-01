const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const fs = require('fs');
const os = require('os');

// Storage file path (local)
const userDataPath = app.getPath('userData');
const storageFile = path.join(userDataPath, 'cardflow-data.json');

// iCloud Drive path (general iCloud Drive folder, accessible by all apps)
const iCloudContainerDir = path.join(
  os.homedir(),
  'Library/Mobile Documents/com~apple~CloudDocs/Plastik'
);
const iCloudFile = path.join(iCloudContainerDir, 'cardflow-data.json');
let iCloudAvailable = false;
let fileWatcher = null;
let pollInterval = null;
let lastICloudWrite = 0;
let mainWindowRef = null;

// Simple file-based storage
let storage = {};

// --- Helpers ---

function safeParseJSON(str, fallback) {
  try { return str ? JSON.parse(str) : fallback; } catch { return fallback; }
}

// --- iCloud functions ---

function checkICloudAvailability() {
  try {
    // Check if iCloud Drive's Mobile Documents root exists
    const mobileDocsRoot = path.join(os.homedir(), 'Library/Mobile Documents');
    if (!fs.existsSync(mobileDocsRoot)) {
      iCloudAvailable = false;
      return false;
    }
    // Create our container directory if it doesn't exist
    if (!fs.existsSync(iCloudContainerDir)) {
      fs.mkdirSync(iCloudContainerDir, { recursive: true });
    }
    iCloudAvailable = true;
    return true;
  } catch (e) {
    console.error('iCloud check failed:', e);
    iCloudAvailable = false;
    return false;
  }
}

function buildStructuredData() {
  return {
    schemaVersion: 1,
    lastModified: new Date().toISOString(),
    lastModifiedBy: 'electron',
    cards: safeParseJSON(storage['cc-tracker-cards'], []),
    pointsBalances: safeParseJSON(storage['cc-tracker-points'], {}),
    companionPasses: safeParseJSON(storage['cc-tracker-passes'], []),
    applications: safeParseJSON(storage['cc-tracker-applications'], []),
    creditPulls: safeParseJSON(storage['cc-tracker-creditpulls'], []),
    holders: safeParseJSON(storage['cc-tracker-holders'], [])
  };
}

function readICloudData() {
  if (!iCloudAvailable) return null;
  try {
    if (fs.existsSync(iCloudFile)) {
      const data = fs.readFileSync(iCloudFile, 'utf8');
      return JSON.parse(data);
    }
  } catch (e) {
    console.error('Error reading iCloud data:', e);
  }
  return null;
}

function writeICloudData(structuredData) {
  if (!iCloudAvailable) return false;
  try {
    if (!fs.existsSync(iCloudContainerDir)) {
      fs.mkdirSync(iCloudContainerDir, { recursive: true });
    }
    structuredData.lastModified = new Date().toISOString();
    structuredData.lastModifiedBy = 'electron';
    structuredData.schemaVersion = 1;
    lastICloudWrite = Date.now();
    fs.writeFileSync(iCloudFile, JSON.stringify(structuredData, null, 2));
    return true;
  } catch (e) {
    console.error('Error writing iCloud data:', e);
    return false;
  }
}

function applyICloudDataToStorage(data) {
  if (data.cards) storage['cc-tracker-cards'] = JSON.stringify(data.cards);
  if (data.pointsBalances) storage['cc-tracker-points'] = JSON.stringify(data.pointsBalances);
  if (data.companionPasses) storage['cc-tracker-passes'] = JSON.stringify(data.companionPasses);
  if (data.applications) storage['cc-tracker-applications'] = JSON.stringify(data.applications);
  if (data.creditPulls) storage['cc-tracker-creditpulls'] = JSON.stringify(data.creditPulls);
  if (data.holders) storage['cc-tracker-holders'] = JSON.stringify(data.holders);
  // Save updated local storage
  try {
    fs.writeFileSync(storageFile, JSON.stringify(storage, null, 2));
  } catch (e) {
    console.error('Error saving after iCloud sync:', e);
  }
}

function handleExternalICloudChange() {
  // Debounce: ignore changes we just wrote
  if (Date.now() - lastICloudWrite < 3000) return;
  const icloudData = readICloudData();
  if (icloudData && icloudData.lastModifiedBy !== 'electron') {
    applyICloudDataToStorage(icloudData);
    if (mainWindowRef && !mainWindowRef.isDestroyed()) {
      mainWindowRef.webContents.send('icloud-data-changed', icloudData);
    }
  }
}

function startICloudWatcher() {
  if (!iCloudAvailable) return;

  // fs.watch for real-time detection
  try {
    if (fs.existsSync(iCloudFile)) {
      fileWatcher = fs.watch(iCloudFile, { persistent: false }, (eventType) => {
        if (eventType === 'change') {
          handleExternalICloudChange();
        }
      });
      fileWatcher.on('error', () => {
        // Silently handle watcher errors, polling is the fallback
      });
    }
  } catch (e) {
    console.error('Error starting iCloud file watcher:', e);
  }

  // Polling fallback every 30 seconds
  pollInterval = setInterval(() => {
    handleExternalICloudChange();
  }, 30000);
}

function stopICloudWatcher() {
  if (fileWatcher) {
    fileWatcher.close();
    fileWatcher = null;
  }
  if (pollInterval) {
    clearInterval(pollInterval);
    pollInterval = null;
  }
}

// --- Local storage ---

function loadStorage() {
  try {
    if (fs.existsSync(storageFile)) {
      const data = fs.readFileSync(storageFile, 'utf8');
      storage = JSON.parse(data);
    }
  } catch (e) {
    console.error('Error loading storage:', e);
    storage = {};
  }
}

function saveStorage() {
  try {
    fs.writeFileSync(storageFile, JSON.stringify(storage, null, 2));
  } catch (e) {
    console.error('Error saving storage:', e);
  }
  // Sync to iCloud
  if (iCloudAvailable) {
    writeICloudData(buildStructuredData());
  }
}

// --- Startup merge: use newer data ---

function mergeOnStartup() {
  if (!iCloudAvailable) return;
  const icloudData = readICloudData();
  if (!icloudData) {
    // No iCloud data yet, push local data to iCloud
    writeICloudData(buildStructuredData());
    return;
  }

  // Compare timestamps
  const localModified = storage['cc-tracker-lastModified'] || '1970-01-01T00:00:00.000Z';
  const icloudModified = icloudData.lastModified || '1970-01-01T00:00:00.000Z';

  if (new Date(icloudModified) > new Date(localModified)) {
    // iCloud is newer, apply to local
    applyICloudDataToStorage(icloudData);
    console.log('Loaded newer data from iCloud');
  } else {
    // Local is newer or same, push to iCloud
    writeICloudData(buildStructuredData());
    console.log('Pushed local data to iCloud');
  }
}

// --- Window ---

function createWindow() {
  const mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 1000,
    minHeight: 700,
    titleBarStyle: 'hiddenInset',
    trafficLightPosition: { x: 20, y: 20 },
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    },
    backgroundColor: '#0f172a'
  });

  // Load the app
  if (process.env.NODE_ENV === 'development' || process.argv.includes('--dev')) {
    mainWindow.loadURL('http://localhost:5173');
    mainWindow.webContents.openDevTools();
  } else {
    mainWindow.loadFile(path.join(__dirname, '../dist-electron/index.html'));
  }

  // Handle window close
  mainWindow.on('close', () => {
    saveStorage();
  });

  return mainWindow;
}

// --- IPC handlers ---

// Storage
ipcMain.handle('storage:get', (event, key) => {
  return storage[key] || null;
});

ipcMain.handle('storage:set', (event, key, value) => {
  storage[key] = value;
  // Track last modified time for merge logic
  storage['cc-tracker-lastModified'] = new Date().toISOString();
  saveStorage();
  return true;
});

ipcMain.handle('storage:delete', (event, key) => {
  delete storage[key];
  saveStorage();
  return true;
});

ipcMain.handle('storage:list', (event, prefix) => {
  const keys = Object.keys(storage);
  if (prefix) {
    return keys.filter(k => k.startsWith(prefix));
  }
  return keys;
});

// iCloud
ipcMain.handle('icloud:status', () => {
  return {
    available: iCloudAvailable,
    path: iCloudFile,
    lastSync: iCloudAvailable && fs.existsSync(iCloudFile)
      ? fs.statSync(iCloudFile).mtime.toISOString()
      : null
  };
});

ipcMain.handle('icloud:sync-now', () => {
  if (!iCloudAvailable) return { success: false, reason: 'iCloud not available' };
  const success = writeICloudData(buildStructuredData());
  return { success };
});

ipcMain.handle('icloud:import', () => {
  const data = readICloudData();
  if (data) {
    applyICloudDataToStorage(data);
    return { success: true, data };
  }
  return { success: false, reason: 'No iCloud data found' };
});

// --- App lifecycle ---

app.whenReady().then(() => {
  loadStorage();
  checkICloudAvailability();
  mergeOnStartup();
  mainWindowRef = createWindow();
  startICloudWatcher();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      mainWindowRef = createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  saveStorage();
  stopICloudWatcher();
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('before-quit', () => {
  saveStorage();
  stopICloudWatcher();
});
