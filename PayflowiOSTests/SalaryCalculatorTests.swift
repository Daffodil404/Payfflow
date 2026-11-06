import XCTest
@testable import PayflowiOS

final class SalaryCalculatorTests: XCTestCase {
    func testHourlySalaryUsesEnteredRate() {
        let settings = SalarySettings(
            period: .hourly,
            grossSalary: Decimal(string: "25.75")!,
            weeklyPaidHours: Decimal(37.5),
            provinceOrTerritory: .ontario
        )

        XCTAssertEqual(SalaryCalculator.hourlyGrossRate(for: settings), Decimal(string: "25.75"))
    }

    func testMonthlySalaryConvertsToHourlyRate() {
        let settings = SalarySettings(
            period: .monthly,
            grossSalary: Decimal(6_500),
            weeklyPaidHours: Decimal(37.5),
            provinceOrTerritory: .ontario
        )

        XCTAssertEqual(SalaryCalculator.hourlyGrossRate(for: settings), Decimal(40))
        XCTAssertEqual(
            NSDecimalNumber(decimal: SalaryCalculator.grossPerSecond(for: settings)).doubleValue,
            40.0 / 3_600.0,
            accuracy: 0.000_000_001
        )
    }

    func testDecimalInputAndValidation() throws {
        XCTAssertEqual(try SalaryCalculator.positiveDecimal(from: " 37.5 "), Decimal(37.5))
        XCTAssertEqual(try SalaryCalculator.positiveDecimal(from: ".5"), Decimal(string: "0.5"))

        assertInputError("", .empty)
        assertInputError("  ", .empty)
        assertInputError("0", .mustBePositive)
        assertInputError("-2.5", .mustBePositive)
        assertInputError("abc", .invalid)
        assertInputError("12abc", .invalid)
    }

    @MainActor
    func testSettingsRestoreFromUserDefaults() throws {
        let suiteName = "PayflowiOSTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = SalarySettings(
            period: .monthly,
            grossSalary: Decimal(6_500),
            weeklyPaidHours: Decimal(37.5),
            provinceOrTerritory: .quebec
        )
        try SalarySettingsStore(defaults: defaults).save(settings)

        XCTAssertEqual(SalarySettingsStore(defaults: defaults).settings, settings)
    }

    private func assertInputError(_ input: String, _ expected: SalaryInputError) {
        XCTAssertThrowsError(try SalaryCalculator.positiveDecimal(from: input)) { error in
            XCTAssertEqual(error as? SalaryInputError, expected)
        }
    }
}
