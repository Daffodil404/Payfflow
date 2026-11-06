import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: SalarySettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var period: SalaryPeriod = .hourly
    @State private var salaryText = ""
    @State private var weeklyHoursText = NSDecimalNumber(decimal: SalarySettings.defaultWeeklyPaidHours).stringValue
    @State private var provinceOrTerritory: CanadianProvinceOrTerritory = .ontario
    @State private var validationMessage: String?

    var body: some View {
        Form {
            Section("Gross salary (before taxes)") {
                Picker("Pay period", selection: $period) {
                    ForEach(SalaryPeriod.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                TextField(period == .hourly ? "Gross salary per hour" : "Gross salary per month", text: $salaryText)
                    .keyboardType(.decimalPad)
                Text("Currency: \(SalarySettings.currencyCode)")
                    .foregroundStyle(.secondary)
            }

            Section("Paid working hours") {
                TextField("Hours per week", text: $weeklyHoursText)
                    .keyboardType(.decimalPad)
            }

            Section("Province or territory") {
                Picker("Province or territory", selection: $provinceOrTerritory) {
                    ForEach(CanadianProvinceOrTerritory.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            }

            if let validationMessage {
                Text(validationMessage)
                    .foregroundStyle(.red)
            }

            Button("Save Settings", action: save)
        }
        .navigationTitle("Settings")
        .onAppear(perform: loadSavedSettings)
    }

    private func loadSavedSettings() {
        guard let settings = store.settings else { return }
        period = settings.period
        salaryText = NSDecimalNumber(decimal: settings.grossSalary).stringValue
        weeklyHoursText = NSDecimalNumber(decimal: settings.weeklyPaidHours).stringValue
        provinceOrTerritory = settings.provinceOrTerritory
    }

    private func save() {
        let salary: Decimal
        let hours: Decimal

        do {
            salary = try SalaryCalculator.positiveDecimal(from: salaryText)
        } catch let error as SalaryInputError {
            validationMessage = "Gross salary: \(error.message)"
            return
        } catch { return }

        do {
            hours = try SalaryCalculator.positiveDecimal(from: weeklyHoursText)
        } catch let error as SalaryInputError {
            validationMessage = "Weekly paid hours: \(error.message)"
            return
        } catch { return }

        let settings = SalarySettings(
            period: period,
            grossSalary: salary,
            weeklyPaidHours: hours,
            provinceOrTerritory: provinceOrTerritory
        )

        do {
            try store.save(settings)
            validationMessage = nil
            dismiss()
        } catch {
            validationMessage = "Could not save settings. Please try again."
        }
    }
}
