const { contextBridge, ipcRenderer } = require('electron');

// Expose storage API to renderer process
contextBridge.exposeInMainWorld('storage', {
  get: async (key, shared = false) => {
    const fullKey = shared ? `shared:${key}` : key;
    const value = await ipcRenderer.invoke('storage:get', fullKey);
    if (value === null) {
      throw new Error(`Key not found: ${key}`);
    }
    return { key, value, shared };
  },
  
  set: async (key, value, shared = false) => {
    const fullKey = shared ? `shared:${key}` : key;
    await ipcRenderer.invoke('storage:set', fullKey, value);
    return { key, value, shared };
  },
  
  delete: async (key, shared = false) => {
    const fullKey = shared ? `shared:${key}` : key;
    await ipcRenderer.invoke('storage:delete', fullKey);
    return { key, deleted: true, shared };
  },
  
  list: async (prefix = '', shared = false) => {
    const fullPrefix = shared ? `shared:${prefix}` : prefix;
    const keys = await ipcRenderer.invoke('storage:list', fullPrefix);
    // Remove the shared: prefix from keys when returning
    const cleanKeys = keys.map(k => shared ? k.replace('shared:', '') : k);
    return { keys: cleanKeys, prefix, shared };
  }
});

// Expose iCloud API to renderer process
contextBridge.exposeInMainWorld('icloud', {
  getStatus: () => ipcRenderer.invoke('icloud:status'),
  syncNow: () => ipcRenderer.invoke('icloud:sync-now'),
  importFromICloud: () => ipcRenderer.invoke('icloud:import'),
  onDataChanged: (callback) => {
    ipcRenderer.on('icloud-data-changed', (event, data) => callback(data));
  }
});
