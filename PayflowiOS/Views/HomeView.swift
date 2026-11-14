import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var settingsStore: SalarySettingsStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var session = WorkSessionStore.load()
    @State private var showsSession = false
    @State private var hasRestoredActivity = false
    @State private var isEndingActivity = false
    @State private var activityMessage: String?
    @State private var showsActivityAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                PayflowTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        header
                        sessionCard
                        rateCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 36)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundStyle(PayflowTheme.accent)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .toolbarBackground(PayflowTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(isPresented: $showsSession) {
                if let session {
                    SessionView(session: session, onStop: stopSession)
                }
            }
            .task { await restoreActivity() }
            .onChange(of: scenePhase) { _, _ in
                if let session, session.isRunning {
                    Task { await PayflowActivityManager.sync(for: session) }
                }
            }
            .alert("Live Activity", isPresented: $showsActivityAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(activityMessage ?? "The Lock Screen timer is unavailable.")
            }
        }
        .tint(PayflowTheme.accent)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                Image(systemName: "circle.hexagongrid.fill")
                Text("PAYFLOW").tracking(3)
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(PayflowTheme.accent)

            Text("Your work, in motion.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var sessionCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Image(systemName: session?.isRunning == true ? "waveform.path" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(PayflowTheme.accent)
                Spacer()
                Text(session?.isRunning == true ? "IN PROGRESS" : "READY")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(PayflowTheme.accent)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(session?.isRunning == true ? "You're on the clock." : "Ready when you are.")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(session?.isRunning == true
                     ? "Open your live session to follow every second and every dollar."
                     : "Start a session to watch your gross earnings grow in real time.")
                    .font(.subheadline)
                    .foregroundStyle(PayflowTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: openOrStartSession) {
                Label(session?.isRunning == true ? "View live session" : "Start session",
                      systemImage: session?.isRunning == true ? "arrow.up.right" : "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(PayflowTheme.background)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(PayflowTheme.accent)
            .disabled(settingsStore.settings == nil || isEndingActivity)

            if settingsStore.settings == nil {
                Text("Add a gross salary in Settings to begin.")
                    .font(.footnote)
                    .foregroundStyle(PayflowTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PayflowTheme.surface, in: RoundedRectangle(cornerRadius: 26))
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .strokeBorder(PayflowTheme.accent.opacity(0.16), lineWidth: 1)
        }
    }

    private var rateCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("YOUR GROSS RATE")
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(PayflowTheme.muted)

            if let settings = settingsStore.settings {
                Text("\(cad(settings.grossSalary, digits: 2)) / \(settings.period == .hourly ? "hour" : "month")")
                    .font(.title3.bold())
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text("Estimated \(cad(SalaryCalculator.grossPerSecond(for: settings), digits: 6)) per second · before taxes")
                    .font(.footnote)
                    .foregroundStyle(PayflowTheme.muted)
            } else {
                Text("No salary configured yet")
                    .foregroundStyle(PayflowTheme.muted)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PayflowTheme.surface, in: RoundedRectangle(cornerRadius: 22))
    }

    private func openOrStartSession() {
        if session?.isRunning == true {
            showsSession = true
            return
        }
        guard let settings = settingsStore.settings else { return }
        let newSession = WorkSession(startedAt: .now, grossPerSecond: SalaryCalculator.grossPerSecond(for: settings))
        session = newSession
        WorkSessionStore.save(newSession)
        showsSession = true
        do {
            try PayflowActivityManager.start(for: newSession)
        } catch {
            activityMessage = error.localizedDescription
            showsActivityAlert = true
        }
    }

    private func stopSession() {
        guard var currentSession = session, currentSession.isRunning else { return }
        currentSession.stop(at: .now)
        session = currentSession
        WorkSessionStore.save(currentSession)
        isEndingActivity = true
        showsSession = false
        Task {
            await PayflowActivityManager.endAll()
            isEndingActivity = false
        }
    }

    private func restoreActivity() async {
        guard !hasRestoredActivity else { return }
        hasRestoredActivity = true

        guard let session, session.isRunning else {
            await PayflowActivityManager.endAll()
            return
        }
        showsSession = true
        do {
            try PayflowActivityManager.ensureRunning(for: session)
            await PayflowActivityManager.sync(for: session)
        } catch {
            activityMessage = error.localizedDescription
            showsActivityAlert = true
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
