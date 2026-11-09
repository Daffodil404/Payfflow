import ActivityKit
import SwiftUI
import WidgetKit

@main
struct PayflowLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        PayflowLiveActivity()
    }
}

struct PayflowLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PayflowActivityAttributes.self) { context in
            HStack(spacing: 16) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.mint)

                VStack(alignment: .leading, spacing: 3) {
                    Text("PAYFLOW · GROSS")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text(context.state.grossAmount)
                        .font(.headline.monospacedDigit())
                        .minimumScaleFactor(0.75)
                    Text("Last synced · before taxes")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 3) {
                    Text("WORKING")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.mint)
                    Text(context.attributes.startedAt, style: .timer)
                        .font(.headline.monospacedDigit())
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .activityBackgroundTint(Color(red: 0.06, green: 0.10, blue: 0.16))
            .activitySystemActionForegroundColor(.mint)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Payflow", systemImage: "dollarsign.circle.fill")
                        .foregroundStyle(.mint)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.startedAt, style: .timer)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LAST SYNCED GROSS · BEFORE TAXES")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(context.state.grossAmount)
                                .font(.title3.bold().monospacedDigit())
                        }
                        Spacer()
                    }
                }
            } compactLeading: {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(.mint)
            } compactTrailing: {
                Text(context.attributes.startedAt, style: .timer)
                    .monospacedDigit()
                    .frame(maxWidth: 72)
            } minimal: {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(.mint)
            }
        }
    }
}
