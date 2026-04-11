import Foundation

private let nugramTimeWithSecondsUserDefaultsKey = "nugram_time_with_seconds"
private let nugramHidePhoneNumberUserDefaultsKey = "nugram_hide_phone_number"

public func nugramTimeWithSecondsEnabled() -> Bool {
    return UserDefaults.standard.bool(forKey: nugramTimeWithSecondsUserDefaultsKey)
}

public func nugramTimeWithSecondsPersistEnabled(_ enabled: Bool) {
    UserDefaults.standard.set(enabled, forKey: nugramTimeWithSecondsUserDefaultsKey)
}

public func nugramHidePhoneNumberEnabled() -> Bool {
    return UserDefaults.standard.bool(forKey: nugramHidePhoneNumberUserDefaultsKey)
}

public func nugramHidePhoneNumberPersistEnabled(_ enabled: Bool) {
    UserDefaults.standard.set(enabled, forKey: nugramHidePhoneNumberUserDefaultsKey)
}
