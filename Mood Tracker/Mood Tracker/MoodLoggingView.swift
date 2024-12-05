import SwiftUI

struct MoodLoggingView: View {
    @EnvironmentObject var viewModel: MoodViewModel
    @State private var selectedMood: MoodType = .happy
    @State private var note: String = ""
    @State private var tags: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("How are you feeling today?")
                    .font(.headline)

                HStack(spacing: 20) {
                    ForEach(MoodType.allCases) { mood in
                        Button(action: {
                            selectedMood = mood
                        }) {
                            Text(mood.emoji)
                                .font(.largeTitle)
                                .padding()
                                .background(selectedMood == mood ? Color.blue.opacity(0.2) : Color.clear)
                                .cornerRadius(10)
                        }
                    }
                }

                TextField("Add a note (optional)", text: $note)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                TextField("Tags (comma-separated)", text: $tags)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button(action: {
                    let mood = Mood(type: selectedMood, note: note, date: Date(), tags: tags.components(separatedBy: ","))
                    viewModel.addMood(mood)
                    alertMessage = "Your mood has been saved successfully!"
                    showAlert = true
                    note = ""
                    tags = ""
                }) {
                    Text("Save Mood")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Log Mood")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Mood Saved"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

