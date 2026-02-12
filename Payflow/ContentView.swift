import SwiftUI

struct PayflowSettings {
    let monthlySalary: Double
    let workDaysInMonth: Int
    let workStartTime: Date
    let workEndTime: Date
    let lunchMinutes: Int
    let refreshIntervalSeconds: Int

    var paidWorkMinutesPerDay: Double {
        let startComponents = Calendar.current.dateComponents([.hour, .minute], from: workStartTime)
        let endComponents = Calendar.current.dateComponents([.hour, .minute], from: workEndTime)
        let startMinutes = Double((startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0))
        let endMinutes = Double((endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0))
        return max(1, endMinutes - startMinutes - Double(lunchMinutes))
    }

    var ratePerMinute: Double {
        let dailySalary = monthlySalary / Double(max(1, workDaysInMonth))
        return dailySalary / paidWorkMinutesPerDay
    }
}

enum WorkState {
    case idle
    case running
}

final class PayflowViewModel: ObservableObject {
    @Published var todayEarning: Double = 0
    @Published var workedSeconds: TimeInterval = 0
    @Published var workState: WorkState = .idle

    private var settings: PayflowSettings
    private var startTime: Date?
    private var timer: Timer?

    init() {
        settings = Self.loadSettings()
    }

    var todayEarningText: String {
        Self.currencyFormatter.string(from: NSNumber(value: todayEarning)) ?? "¥0.00"
    }

    var ratePerMinuteText: String {
        Self.currencyFormatter.string(from: NSNumber(value: settings.ratePerMinute)) ?? "¥0.00"
    }

    var workedDurationText: String {
        let total = Int(workedSeconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    var isRunning: Bool {
        workState == .running
    }

    func startWork() {
        guard !isRunning else { return }
        refreshSettingsFromStorage()
        startTime = Date()
        workedSeconds = 0
        todayEarning = 0
        workState = .running
        startTimer()
    }

    func endWork() {
        timer?.invalidate()
        timer = nil
        workState = .idle
    }

    func refreshSettingsFromStorage() {
        settings = Self.loadSettings()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(settings.refreshIntervalSeconds), repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard isRunning, let startTime else { return }
        if !Calendar.current.isDateInToday(startTime) {
            workedSeconds = 0
            todayEarning = 0
            endWork()
            return
        }

        workedSeconds = Date().timeIntervalSince(startTime)
        let workedMinutes = workedSeconds / 60.0
        todayEarning = workedMinutes * settings.ratePerMinute
    }

    private static func loadSettings() -> PayflowSettings {
        let defaults = UserDefaults.standard
        let monthlySalary = defaults.double(forKey: "monthlySalary")
        let safeSalary = monthlySalary > 0 ? monthlySalary : 0

        let workDays = defaults.integer(forKey: "workDaysInMonth")
        let safeWorkDays = workDays > 0 ? workDays : 22

        let workStart = defaults.object(forKey: "workStartTime") as? Date ?? time(hour: 9, minute: 0)
        let workEnd = defaults.object(forKey: "workEndTime") as? Date ?? time(hour: 18, minute: 0)

        let lunch = defaults.object(forKey: "lunchMinutes") == nil ? 60 : defaults.integer(forKey: "lunchMinutes")
        let safeLunch = max(0, lunch)

        let refresh = defaults.integer(forKey: "refreshIntervalSeconds")
        let safeRefresh = [1, 2, 3].contains(refresh) ? refresh : 1

        return PayflowSettings(
            monthlySalary: safeSalary,
            workDaysInMonth: safeWorkDays,
            workStartTime: workStart,
            workEndTime: workEnd,
            lunchMinutes: safeLunch,
            refreshIntervalSeconds: safeRefresh
        )
    }

    private static func time(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}

struct StatusMenuView: View {
    @EnvironmentObject var vm: PayflowViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "yensign.circle.fill")
                    .foregroundStyle(.green)
                Text("今日已赚")
                    .font(.headline)
                Spacer()
                Text(vm.todayEarningText)
                    .font(.headline.monospacedDigit())
            }

            HStack {
                Text("当前速率")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(vm.ratePerMinuteText)/分钟")
                    .monospacedDigit()
            }

            HStack {
                Text("已工作时长")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(vm.workedDurationText)
                    .monospacedDigit()
            }

            Divider()

            HStack(spacing: 8) {
                Button("开始工作") {
                    vm.startWork()
                }
                .disabled(vm.isRunning)

                Button("结束工作") {
                    vm.endWork()
                }
                .disabled(!vm.isRunning)
            }

            Button("设置") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "settings")
            }

            Divider()

            Button("退出 Payflow") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 300)
    }
}

struct ContentView: View {
    var onSaved: (() -> Void)? = nil

    @State private var monthlySalaryText: String = ""
    @State private var workDaysText: String = "22"
    @State private var workStartTime: Date = Self.time(hour: 9, minute: 0)
    @State private var workEndTime: Date = Self.time(hour: 18, minute: 0)
    @State private var lunchMinutesText: String = "60"
    @State private var refreshIntervalSeconds: Int = 1
    @State private var message: String?
    @State private var isSuccessMessage = false

    private static let refreshOptions = [1, 2, 3]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payflow 设置")
                .font(.title2.bold())

            Form {
                LabeledContent("月薪") {
                    TextField("例如 12000", text: $monthlySalaryText)
                        .frame(width: 180)
                        .textFieldStyle(.roundedBorder)
                }

                LabeledContent("本月工作日天数") {
                    TextField("22", text: $workDaysText)
                        .frame(width: 120)
                        .textFieldStyle(.roundedBorder)
                }

                LabeledContent("上班时间") {
                    DatePicker(
                        "",
                        selection: $workStartTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                }

                LabeledContent("下班时间") {
                    DatePicker(
                        "",
                        selection: $workEndTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                }

                LabeledContent("午休分钟") {
                    TextField("60", text: $lunchMinutesText)
                        .frame(width: 120)
                        .textFieldStyle(.roundedBorder)
                }

                LabeledContent("更新频率") {
                    Picker("更新频率", selection: $refreshIntervalSeconds) {
                        ForEach(Self.refreshOptions, id: \.self) { seconds in
                            Text("\(seconds) 秒").tag(seconds)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
            }

            if let message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(isSuccessMessage ? .green : .red)
            }

            HStack {
                Spacer()
                Button("保存设置", action: saveSettings)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460)
        .onAppear(perform: loadSettings)
    }

    private func saveSettings() {
        guard let monthlySalary = Double(monthlySalaryText), monthlySalary > 0 else {
            message = "月薪必须大于 0"
            isSuccessMessage = false
            return
        }

        guard let workDaysInMonth = Int(workDaysText), workDaysInMonth > 0 else {
            message = "本月工作日天数必须大于 0"
            isSuccessMessage = false
            return
        }

        let totalMinutes = minutesBetween(start: workStartTime, end: workEndTime)
        guard totalMinutes > 0 else {
            message = "下班时间必须晚于上班时间"
            isSuccessMessage = false
            return
        }

        let lunchMinutes = Int(lunchMinutesText) ?? 60
        guard lunchMinutes >= 0 else {
            message = "午休分钟不能为负数"
            isSuccessMessage = false
            return
        }

        guard lunchMinutes < totalMinutes else {
            message = "午休分钟必须小于总工作分钟"
            isSuccessMessage = false
            return
        }

        let defaults = UserDefaults.standard
        defaults.set(monthlySalary, forKey: "monthlySalary")
        defaults.set(workDaysInMonth, forKey: "workDaysInMonth")
        defaults.set(workStartTime, forKey: "workStartTime")
        defaults.set(workEndTime, forKey: "workEndTime")
        defaults.set(lunchMinutes, forKey: "lunchMinutes")
        defaults.set(refreshIntervalSeconds, forKey: "refreshIntervalSeconds")

        message = "保存成功"
        isSuccessMessage = true
        onSaved?()
    }

    private func loadSettings() {
        let defaults = UserDefaults.standard

        let monthly = defaults.double(forKey: "monthlySalary")
        if monthly > 0 {
            monthlySalaryText = String(format: "%.2f", monthly)
        }

        let workDays = defaults.integer(forKey: "workDaysInMonth")
        if workDays > 0 {
            workDaysText = String(workDays)
        }

        if let savedStart = defaults.object(forKey: "workStartTime") as? Date {
            workStartTime = savedStart
        }
        if let savedEnd = defaults.object(forKey: "workEndTime") as? Date {
            workEndTime = savedEnd
        }

        if defaults.object(forKey: "lunchMinutes") != nil {
            lunchMinutesText = String(defaults.integer(forKey: "lunchMinutes"))
        }

        let refresh = defaults.integer(forKey: "refreshIntervalSeconds")
        if Self.refreshOptions.contains(refresh) {
            refreshIntervalSeconds = refresh
        }
    }

    private func minutesBetween(start: Date, end: Date) -> Int {
        let startComponents = Calendar.current.dateComponents([.hour, .minute], from: start)
        let endComponents = Calendar.current.dateComponents([.hour, .minute], from: end)
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        return endMinutes - startMinutes
    }

    private static func time(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
