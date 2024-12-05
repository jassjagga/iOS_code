import SwiftUI

@main
struct MoodTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            QuoteScreen()
        }
    }
}

struct QuoteScreen: View {
    let quotes = [
        "Happiness is not something ready-made. It comes from your own actions.",
        "Keep your face always toward the sunshine—and shadows will fall behind you.",
        "The best way to predict the future is to create it.",
        "Life is what happens when you're busy making other plans.",
        "Success is not final, failure is not fatal: It is the courage to continue that counts."
    ]
    
    var body: some View {
        VStack {
            Spacer()
            
            Text(quotes.randomElement() ?? "Welcome!")
                .font(.title)
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
            
            NavigationLink(destination: MoodScreen()) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(Color.gray)
                    .padding(.bottom, 20)
            }
        }
        .padding()
    }
}

struct MoodScreen: View {
    let moods = ["Happy", "Sad", "Angry", "Relaxed", "Boring", "Annoyed"]
    let emojis = ["😊", "😢", "😡", "😌", "😴", "😒"]
    
    @State private var selectedMood: String = ""
    
    var body: some View {
        VStack {
            Text("How are you feeling?")
                .font(.largeTitle)
                .padding()
            
            Spacer()
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                ForEach(0..<moods.count, id: \.self) { index in
                    Button(action: {
                        selectedMood = moods[index]
                    }) {
                        VStack {
                            Text(emojis[index])
                                .font(.largeTitle)
                            Text(moods[index])
                                .font(.headline)
                        }
                        .padding()
                        .background(selectedMood == moods[index] ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
            }
            
            Spacer()
            
            if !selectedMood.isEmpty {
                NavigationLink(destination: WhyScreen(selectedMood: selectedMood)) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(Color.gray)
                        .padding(.bottom, 20)
                }
            }
        }
        .padding()
    }
}

struct WhyScreen: View {
    let selectedMood: String
    @State private var reason = ""
    
    var body: some View {
        VStack {
            Text("Why?")
                .font(.largeTitle)
                .padding()
            
            TextField("Enter one word (e.g., Work, School)", text: $reason)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            if !reason.isEmpty {
                NavigationLink(destination: InsightScreen(mood: selectedMood, reason: reason)) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(Color.gray)
                        .padding(.bottom, 20)
                }
            }
        }
        .padding()
    }
}

struct InsightScreen: View {
    let mood: String
    let reason: String
    
    var body: some View {
        VStack {
            Text("Summary of Your Day")
                .font(.largeTitle)
                .padding()
            
            Text("You felt \(mood) because of \(reason).")
                .font(.headline)
                .padding()
            
            Text("Quote: \"Keep pushing forward, and happiness will follow.\"")
                .font(.subheadline)
                .italic()
                .padding()
            
            NavigationLink(destination: WeekSummaryScreen()) {
                Text("Weekly Summary")
                    .font(.headline)
                    .foregroundColor(Color.gray)
                    .padding(.bottom, 20)
            }
            
            NavigationLink(destination: ContentView()) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(Color.gray)
            }
        }
        .padding()
    }
}

struct WeekSummaryScreen: View {
    var body: some View {
        VStack {
            Text("Weekly Summary")
                .font(.largeTitle)
                .padding()
            
            Text("This week, your top moods were:")
                .font(.headline)
                .padding()
            
            Text("Happy: 3 days")
            Text("Sad: 2 days")
            Text("Angry: 1 day")
            
            Text("Quote: \"Your emotions guide your growth.\"")
                .font(.subheadline)
                .italic()
                .padding()
            
            NavigationLink(destination: ContentView()) {
                Text("Back to Start")
                    .font(.headline)
                    .foregroundColor(Color.gray)
            }
        }
        .padding()
    }
}

