import Combine
import Foundation

@MainActor
final class SalarySettingsStore: ObservableObject {
    @Published private(set) var settings: SalarySettings?

    private static let storageKey = "payflow.ios.salarySettings"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode(SalarySettings.self, from: data),
           saved.grossSalary > 0, saved.weeklyPaidHours > 0 {
            settings = saved
        }
    }

    func save(_ settings: SalarySettings) throws {
        let data = try JSONEncoder().encode(settings)
        defaults.set(data, forKey: Self.storageKey)
        self.settings = settings
    }
}
