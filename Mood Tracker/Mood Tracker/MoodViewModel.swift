import Foundation
import Combine

class MoodViewModel: ObservableObject {
    @Published var moods: [Mood] = []
    @Published var selectedTheme: String = "Default"
    
    private let storageKey = "moods"
    private let themeKey = "theme"

    init() {
        loadMoods()
        loadTheme()
    }

    func addMood(_ mood: Mood) {
        moods.append(mood)
        saveMoods()
    }

    func deleteMood(at offsets: IndexSet) {
        moods.remove(atOffsets: offsets)
        saveMoods()
    }

    func saveTheme(_ theme: String) {
        selectedTheme = theme
        UserDefaults.standard.set(theme, forKey: themeKey)
    }

    func loadTheme() {
        selectedTheme = UserDefaults.standard.string(forKey: themeKey) ?? "Default"
    }

    private func saveMoods() {
        if let encoded = try? JSONEncoder().encode(moods) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadMoods() {
        if let savedData = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Mood].self, from: savedData) {
            moods = decoded
        }
    }
}

