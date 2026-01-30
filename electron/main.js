const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const fs = require('fs');

// Storage file path
const userDataPath = app.getPath('userData');
const storageFile = path.join(userDataPath, 'cardflow-data.json');

// Simple file-based storage
let storage = {};

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
}

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
}

// IPC handlers for storage
ipcMain.handle('storage:get', (event, key) => {
  return storage[key] || null;
});

ipcMain.handle('storage:set', (event, key, value) => {
  storage[key] = value;
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

app.whenReady().then(() => {
  loadStorage();
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  saveStorage();
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('before-quit', () => {
  saveStorage();
});
