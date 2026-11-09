import SwiftUI

struct SessionView: View {
    let session: WorkSession
    let onStop: () -> Void

    var body: some View {
        ZStack {
            PayflowTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(PayflowTheme.accent)
                        .frame(width: 8, height: 8)
                    Text("SESSION IN PROGRESS")
                        .font(.caption.weight(.bold))
                        .tracking(1.5)
                        .foregroundStyle(PayflowTheme.accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 24)

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(spacing: 42) {
                        VStack(spacing: 12) {
                            Text("GROSS EARNED")
                                .font(.caption.weight(.bold))
                                .tracking(2)
                                .foregroundStyle(PayflowTheme.muted)
                            Text(cad(session.grossEarnings(at: context.date)))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .minimumScaleFactor(0.55)
                                .lineLimit(1)
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                            Text("Before taxes")
                                .font(.subheadline)
                                .foregroundStyle(PayflowTheme.muted)
                        }

                        RoundedRectangle(cornerRadius: 1)
                            .fill(PayflowTheme.accent.opacity(0.22))
                            .frame(width: 72, height: 2)

                        VStack(spacing: 10) {
                            Text("TIME WORKED")
                                .font(.caption.weight(.bold))
                                .tracking(2)
                                .foregroundStyle(PayflowTheme.muted)
                            Text(duration(session.elapsedSeconds(at: context.date)))
                                .font(.system(size: 44, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(PayflowTheme.accent)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                Spacer(minLength: 24)

                VStack(spacing: 18) {
                    Text("Your session keeps counting when you lock your phone.")
                        .font(.footnote)
                        .foregroundStyle(PayflowTheme.muted)
                        .multilineTextAlignment(.center)

                    Button(action: onStop) {
                        Label("Stop session", systemImage: "stop.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(Color(red: 0.78, green: 0.32, blue: 0.33))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 28)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Payflow")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .toolbarBackground(PayflowTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func duration(_ seconds: Int) -> String {
        String(format: "%02d:%02d:%02d", seconds / 3_600, (seconds % 3_600) / 60, seconds % 60)
    }

    private func cad(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_CA")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 6
        formatter.maximumFractionDigits = 6
        return "\(SalarySettings.currencyCode) $" + (formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "0")
    }
}
