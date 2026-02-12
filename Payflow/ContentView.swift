import SwiftUI

struct ContentView: View {
    @State private var monthlySalaryText: String = ""
    @State private var workDaysText: String = "22"
    @State private var workStartTime: Date = Self.time(hour: 9, minute: 0)
    @State private var workEndTime: Date = Self.time(hour: 18, minute: 0)
    @State private var lunchMinutesText: String = "60"
    @State private var refreshIntervalSeconds: Int = 1
    @State private var message: String?

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
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("保存设置", action: saveSettings)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460)
    }

    private func saveSettings() {
        guard let monthlySalary = Double(monthlySalaryText), monthlySalary > 0 else {
            message = "月薪必须大于 0"
            return
        }

        guard let workDaysInMonth = Int(workDaysText), workDaysInMonth > 0 else {
            message = "本月工作日天数必须大于 0"
            return
        }

        let totalMinutes = minutesBetween(start: workStartTime, end: workEndTime)
        guard totalMinutes > 0 else {
            message = "下班时间必须晚于上班时间"
            return
        }

        let lunchMinutes = Int(lunchMinutesText) ?? 60
        guard lunchMinutes >= 0 else {
            message = "午休分钟不能为负数"
            return
        }

        guard lunchMinutes < totalMinutes else {
            message = "午休分钟必须小于总工作分钟"
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
