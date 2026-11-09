import ActivityKit
import Foundation

@MainActor
enum PayflowActivityManager {
    static func ensureRunning(for session: WorkSession) throws {
        if Activity<PayflowActivityAttributes>.activities.isEmpty {
            try start(for: session)
        }
    }

    static func start(for session: WorkSession) throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw PayflowActivityError.disabled
        }

        let attributes = PayflowActivityAttributes(startedAt: session.startedAt)
        let state = PayflowActivityAttributes.ContentState(grossAmount: formattedGross(0))
        _ = try Activity<PayflowActivityAttributes>.request(
            attributes: attributes,
            content: ActivityContent(state: state, staleDate: nil),
            pushType: nil
        )
    }

    static func sync(for session: WorkSession, at date: Date = .now) async {
        let state = PayflowActivityAttributes.ContentState(
            grossAmount: formattedGross(session.grossEarnings(at: date))
        )
        for activity in Activity<PayflowActivityAttributes>.activities {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    static func endAll() async {
        for activity in Activity<PayflowActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private static func formattedGross(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_CA")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 4
        return "\(SalarySettings.currencyCode) $" + (formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "0.0000")
    }
}

enum PayflowActivityError: LocalizedError {
    case disabled

    var errorDescription: String? {
        "Live Activities are disabled for Payflow. Enable them in iOS Settings to see the Lock Screen timer."
    }
}
