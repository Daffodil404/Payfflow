import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Earnings")
                        .font(.headline)
                    Text("CAD $0.00")
                        .font(.largeTitle.bold())
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
        }
    }
}
