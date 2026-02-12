//
//  PayflowApp.swift
//  Payflow
//
//  Created by Yanyu Woo on 2026/2/10.
//

import SwiftUI

@main
struct PayflowApp: App {
    @StateObject private var vm = PayflowViewModel()

    var body: some Scene {
        MenuBarExtra {
            StatusMenuView()
                .environmentObject(vm)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "yensign.circle.fill")
                Text(vm.todayEarningText)
                    .monospacedDigit()
            }
        }
        .menuBarExtraStyle(.window)

        Window("Payflow 设置", id: "settings") {
            ContentView {
                vm.refreshSettingsFromStorage()
            }
            .padding(12)
            .frame(minWidth: 520, minHeight: 420)
        }
    }
}
