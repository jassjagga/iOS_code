import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: MoodViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Today’s Affirmation")
                    .font(.title)
                    .padding()
                Text("You are capable of amazing things!")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()

                Spacer()

                NavigationLink(destination: MoodLoggingView()) {
                    Text("Log a Mood")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                NavigationLink(destination: MoodInsightsView()) {
                    Text("View Insights")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Mood Tracker")
        }
    }
}

