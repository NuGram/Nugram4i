import Foundation

private let nugramDisableNumberRoundingUserDefaultsKey = "nugram_disable_number_rounding"

private let nugramDisableNumberRoundingFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    formatter.minimumFractionDigits = 0
    formatter.usesGroupingSeparator = true
    return formatter
}()

public func nugramDisableNumberRoundingEnabled() -> Bool {
    return UserDefaults.standard.bool(forKey: nugramDisableNumberRoundingUserDefaultsKey)
}

public func nugramDisableNumberRoundingPersistEnabled(_ enabled: Bool) {
    UserDefaults.standard.set(enabled, forKey: nugramDisableNumberRoundingUserDefaultsKey)
}

public func nugramDisableNumberRoundingFormat(_ value: Int64) -> String {
    nugramDisableNumberRoundingFormatter.locale = Locale.current
    return nugramDisableNumberRoundingFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
}
