import Foundation

private let nugramLegacyUnlimitedLocalFiltersUserDefaultsKey = "nugram_unlimited_local_filters"
private let nugramUnlimitedPinsUserDefaultsKey = "nugram_unlimited_pins"
private let nugramUnlimitedFoldersUserDefaultsKey = "nugram_unlimited_folders"
private let nugramUnlimitedLoginsUserDefaultsKey = "nugram_unlimited_logins"

private func nugramBool(forKey key: String, default defaultValue: Bool) -> Bool {
    let userDefaults = UserDefaults.standard
    guard userDefaults.object(forKey: key) != nil else {
        return defaultValue
    }
    return userDefaults.bool(forKey: key)
}

public func nugramUnlimitedPinsEnabled() -> Bool {
    let userDefaults = UserDefaults.standard
    let legacyValue = userDefaults.bool(forKey: nugramLegacyUnlimitedLocalFiltersUserDefaultsKey)
    return nugramBool(forKey: nugramUnlimitedPinsUserDefaultsKey, default: legacyValue)
}

public func nugramUnlimitedPinsPersistEnabled(_ enabled: Bool) {
    UserDefaults.standard.set(enabled, forKey: nugramUnlimitedPinsUserDefaultsKey)
}

public func nugramUnlimitedFoldersEnabled() -> Bool {
    let userDefaults = UserDefaults.standard
    let legacyValue = userDefaults.bool(forKey: nugramLegacyUnlimitedLocalFiltersUserDefaultsKey)
    return nugramBool(forKey: nugramUnlimitedFoldersUserDefaultsKey, default: legacyValue)
}

public func nugramUnlimitedFoldersPersistEnabled(_ enabled: Bool) {
    UserDefaults.standard.set(enabled, forKey: nugramUnlimitedFoldersUserDefaultsKey)
}

public func nugramUnlimitedLoginsEnabled() -> Bool {
    return nugramBool(forKey: nugramUnlimitedLoginsUserDefaultsKey, default: true)
}

public func nugramUnlimitedLoginsPersistEnabled(_ enabled: Bool) {
    UserDefaults.standard.set(enabled, forKey: nugramUnlimitedLoginsUserDefaultsKey)
}

public func nugramCanUseLocalFolderColors(isPremium: Bool) -> Bool {
    return isPremium || nugramUnlimitedFoldersEnabled()
}
