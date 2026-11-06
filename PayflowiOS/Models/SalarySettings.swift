import Foundation

enum SalaryPeriod: String, CaseIterable, Codable, Identifiable {
    case hourly = "Hourly"
    case monthly = "Monthly"

    var id: String { rawValue }
}

enum CanadianProvinceOrTerritory: String, CaseIterable, Codable, Identifiable {
    case alberta = "Alberta"
    case britishColumbia = "British Columbia"
    case manitoba = "Manitoba"
    case newBrunswick = "New Brunswick"
    case newfoundlandAndLabrador = "Newfoundland and Labrador"
    case northwestTerritories = "Northwest Territories"
    case novaScotia = "Nova Scotia"
    case nunavut = "Nunavut"
    case ontario = "Ontario"
    case princeEdwardIsland = "Prince Edward Island"
    case quebec = "Quebec"
    case saskatchewan = "Saskatchewan"
    case yukon = "Yukon"

    var id: String { rawValue }
}

struct SalarySettings: Codable, Equatable {
    static let currencyCode = "CAD"
    static let defaultWeeklyPaidHours = Decimal(37.5)

    let period: SalaryPeriod
    let grossSalary: Decimal
    let weeklyPaidHours: Decimal
    let provinceOrTerritory: CanadianProvinceOrTerritory
}
