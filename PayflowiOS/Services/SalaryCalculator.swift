import Foundation

enum SalaryInputError: Error, Equatable {
    case empty
    case invalid
    case mustBePositive

    var message: String {
        switch self {
        case .empty: "Enter a value."
        case .invalid: "Enter a valid decimal number."
        case .mustBePositive: "Enter a value greater than zero."
        }
    }
}

enum SalaryCalculator {
    static func positiveDecimal(from input: String) throws -> Decimal {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { throw SalaryInputError.empty }

        let decimalPattern = #"^-?(?:[0-9]+(?:\.[0-9]+)?|\.[0-9]+)$"#
        guard value.range(of: decimalPattern, options: .regularExpression) != nil,
              let amount = Decimal(string: value, locale: Locale(identifier: "en_CA")) else {
            throw SalaryInputError.invalid
        }
        guard amount > 0 else { throw SalaryInputError.mustBePositive }
        return amount
    }

    static func hourlyGrossRate(for settings: SalarySettings) -> Decimal {
        switch settings.period {
        case .hourly:
            settings.grossSalary
        case .monthly:
            settings.grossSalary * 12 / (52 * settings.weeklyPaidHours)
        }
    }

    static func grossPerSecond(for settings: SalarySettings) -> Decimal {
        hourlyGrossRate(for: settings) / 3_600
    }
}
