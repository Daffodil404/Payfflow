import Foundation

struct WorkSession: Codable {
    let startedAt: Date
    let grossPerSecond: Decimal
    private(set) var stoppedAt: Date?

    var isRunning: Bool { stoppedAt == nil }

    func elapsedSeconds(at date: Date) -> Int {
        let elapsed = (stoppedAt ?? date).timeIntervalSince(startedAt)
        return max(0, Int(elapsed))
    }

    func grossEarnings(at date: Date) -> Decimal {
        grossPerSecond * Decimal(elapsedSeconds(at: date))
    }

    mutating func stop(at date: Date) {
        guard isRunning else { return }
        stoppedAt = max(startedAt, date)
    }
}

enum WorkSessionStore {
    private static let storageKey = "payflow.ios.workSession"

    static func load(defaults: UserDefaults = .standard) -> WorkSession? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(WorkSession.self, from: data)
    }

    static func save(_ session: WorkSession, defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
