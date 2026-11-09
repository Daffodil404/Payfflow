import ActivityKit
import Foundation

struct PayflowActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// A snapshot. The system-managed elapsed timer remains live while the app is suspended.
        let grossAmount: String
    }

    let startedAt: Date
}
