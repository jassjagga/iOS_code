import SwiftUI

struct MoodInsightsView: View {
    @EnvironmentObject var viewModel: MoodViewModel

    var body: some View {
        NavigationView {
            VStack {
                Text("Mood Trends")
                    .font(.largeTitle)
                    .padding()

                // Example chart placeholder
                List {
                    ForEach(MoodType.allCases) { mood in
                        HStack {
                            Text("\(mood.emoji) \(mood.rawValue)")
                            Spacer()
                            Text("\(viewModel.moods.filter { $0.type == mood }.count)")
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())

                Spacer()
            }
            .navigationTitle("Insights")
        }
    }
}

