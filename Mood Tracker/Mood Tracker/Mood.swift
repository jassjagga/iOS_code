import Foundation

enum MoodType: String, CaseIterable, Identifiable, Codable {
    case happy = "Happy"
    case sad = "Sad"
    case angry = "Angry"
    case anxious = "Anxious"
    case excited = "Excited"

    var id: String { self.rawValue }
    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .sad: return "😢"
        case .angry: return "😡"
        case .anxious: return "😰"
        case .excited: return "😄"
        }
    }
    var color: String {
        switch self {
        case .happy: return "MoodHappy"
        case .sad: return "MoodSad"
        case .angry: return "MoodAngry"
        case .anxious: return "MoodAnxious"
        case .excited: return "MoodExcited"
        }
    }
}

struct Mood: Identifiable, Codable {
    var id: UUID = UUID()
    var type: MoodType
    var note: String
    var date: Date
    var tags: [String]
}

