import SwiftUI

struct SettingsView: View {
    @Environment(DataStore.self) private var store
    @State private var newHolder = ""
    @State private var apiKeyInput = ""
    @State private var showApiKey = false
    @State private var apiKeySaved = false

    var body: some View {
        Form {
            // Account Holders
            Section {
                ForEach(store.holders, id: \.self) { holder in
                    HStack {
                        let colors = ColorTheme.holderColor(for: holder, in: store.holders)
                        Text(holder)
                            .foregroundColor(colors.text)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(colors.bg)
                            .cornerRadius(8)
                        Spacer()
                        Text("\(store.cards.filter { $0.holder == holder }.count) cards")
                            .font(.caption)
                            .foregroundColor(ColorTheme.textMuted)
                    }
                    .listRowBackground(ColorTheme.cardBg)
                    .swipeActions(edge: .trailing) {
                        if store.holders.count > 1 {
                            Button(role: .destructive) {
                                store.removeHolder(holder)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }

                HStack {
                    TextField("New holder name", text: $newHolder)
                        .foregroundColor(ColorTheme.textPrimary)

                    Button(action: addHolder) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(newHolder.isEmpty ? ColorTheme.textMuted : ColorTheme.gold)
                    }
                    .disabled(newHolder.isEmpty)
                }
                .listRowBackground(ColorTheme.cardBg)
            } header: {
                Text("Account Holders")
                    .foregroundColor(ColorTheme.textSecondary)
            }

            // API Key
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if showApiKey {
                            TextField("sk-ant-...", text: $apiKeyInput)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(ColorTheme.textPrimary)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("sk-ant-...", text: $apiKeyInput)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(ColorTheme.textPrimary)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }

                        Button(action: { showApiKey.toggle() }) {
                            Image(systemName: showApiKey ? "eye.slash" : "eye")
                                .foregroundColor(ColorTheme.textMuted)
                        }
                    }
                }
                .listRowBackground(ColorTheme.cardBg)

                HStack(spacing: 12) {
                    Button(action: saveApiKey) {
                        HStack(spacing: 6) {
                            Image(systemName: apiKeySaved ? "checkmark.circle.fill" : "key.fill")
                                .foregroundColor(apiKeySaved ? ColorTheme.green : ColorTheme.gold)
                            Text(apiKeySaved ? "Saved" : "Save Key")
                                .foregroundColor(apiKeySaved ? ColorTheme.green : ColorTheme.gold)
                        }
                    }
                    .disabled(apiKeyInput.isEmpty)

                    Spacer()

                    if !store.apiKey.isEmpty {
                        Button(action: clearApiKey) {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                    .foregroundColor(ColorTheme.red)
                                Text("Clear Key")
                                    .foregroundColor(ColorTheme.red)
                            }
                        }
                    }
                }
                .listRowBackground(ColorTheme.cardBg)

                if store.apiKey.isEmpty {
                    Text("An Anthropic API key is required for statement parsing and card analysis features.")
                        .font(.caption)
                        .foregroundColor(ColorTheme.textMuted)
                        .listRowBackground(ColorTheme.cardBg)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(ColorTheme.green)
                        Text("API key is configured")
                            .font(.caption)
                            .foregroundColor(ColorTheme.green)
                    }
                    .listRowBackground(ColorTheme.cardBg)
                }
            } header: {
                Text("Anthropic API Key")
                    .foregroundColor(ColorTheme.textSecondary)
            }

            // iCloud Sync
            Section {
                HStack {
                    Image(systemName: store.iCloudAvailable ? "icloud.fill" : "icloud.slash")
                        .foregroundColor(store.iCloudAvailable ? ColorTheme.green : ColorTheme.textMuted)
                    Text(store.iCloudAvailable ? "iCloud Connected" : "iCloud Unavailable")
                        .foregroundColor(ColorTheme.textPrimary)
                    Spacer()
                    if store.iCloudAvailable {
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(ColorTheme.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(ColorTheme.green.opacity(0.15))
                            .cornerRadius(6)
                    }
                }
                .listRowBackground(ColorTheme.cardBg)

                if let syncDate = store.lastSyncDate {
                    HStack {
                        Text("Last Sync")
                            .foregroundColor(ColorTheme.textSecondary)
                        Spacer()
                        Text(syncDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(ColorTheme.textMuted)
                    }
                    .listRowBackground(ColorTheme.cardBg)
                }

                if store.iCloudAvailable {
                    Button(action: { store.syncNow() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Sync Now")
                        }
                        .foregroundColor(ColorTheme.blue)
                    }
                    .listRowBackground(ColorTheme.cardBg)
                }
            } header: {
                Text("iCloud Sync")
                    .foregroundColor(ColorTheme.textSecondary)
            }

            // About
            Section {
                HStack {
                    Text("App")
                        .foregroundColor(ColorTheme.textSecondary)
                    Spacer()
                    Text("CardFlow")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(ColorTheme.gold)
                }
                .listRowBackground(ColorTheme.cardBg)

                HStack {
                    Text("Version")
                        .foregroundColor(ColorTheme.textSecondary)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .font(.caption)
                        .foregroundColor(ColorTheme.textMuted)
                }
                .listRowBackground(ColorTheme.cardBg)

                HStack {
                    Text("Build")
                        .foregroundColor(ColorTheme.textSecondary)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .font(.caption)
                        .foregroundColor(ColorTheme.textMuted)
                }
                .listRowBackground(ColorTheme.cardBg)
            } header: {
                Text("About")
                    .foregroundColor(ColorTheme.textSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(ColorTheme.background)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            apiKeyInput = store.apiKey
        }
    }

    // MARK: - Actions

    private func addHolder() {
        let trimmed = newHolder.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.addHolder(trimmed)
        newHolder = ""
    }

    private func saveApiKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.saveApiKey(trimmed)
        apiKeySaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            apiKeySaved = false
        }
    }

    private func clearApiKey() {
        store.saveApiKey("")
        apiKeyInput = ""
    }
}
