import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var settingsStore: SalarySettingsStore

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's gross earnings (before taxes)")
                        .font(.headline)
                    Text("\(SalarySettings.currencyCode) $0.00")
                        .font(.largeTitle.bold())
                }

                if let settings = settingsStore.settings {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Configured gross salary (before taxes)")
                            .font(.headline)
                        Text("\(cad(settings.grossSalary, digits: 2)) / \(settings.period == .hourly ? "hour" : "month")")

                        Text("Estimated gross earnings per second (before taxes)")
                            .font(.headline)
                        Text(cad(SalaryCalculator.grossPerSecond(for: settings), digits: 6))
                    }
                } else {
                    Text("Set your gross salary to see an estimated rate.")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Session status")
                    Spacer()
                    Text("Not Started")
                        .foregroundStyle(.secondary)
                }

                Button("Start") {}
                    .buttonStyle(.borderedProminent)
                    .disabled(true)

                Spacer()
            }
            .padding()
            .navigationTitle("Payflow")
            .toolbar {
                NavigationLink("Settings") {
                    SettingsView()
                }
            }
        }
    }

    private func cad(_ amount: Decimal, digits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_CA")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = digits
        formatter.maximumFractionDigits = digits
        return "\(SalarySettings.currencyCode) $" + (formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "0")
    }
}
