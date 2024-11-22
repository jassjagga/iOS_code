import SwiftUI

struct CardMatchingGame: View {
    @State private var deck: [Card] = Card.generateShuffledDeck()
    @State private var flippedCards: [Card] = []
    @State private var matchedCards: Set<Card> = []
    @State private var player1Score: Int = 0
    @State private var player2Score: Int = 0
    @State private var currentPlayer: Int = 1
    @State private var showWinningMessage: Bool = false
    @State private var isProcessing: Bool = false
    @State private var player1Name: String = "Player 1"
    @State private var player2Name: String = "Player 2"
    @State private var singlePlayerMode: Bool = false
    @State private var showModeSelection: Bool = true

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if showModeSelection {
                    VStack(spacing: 20) {
                        Text("Select Game Mode")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()

                        Button("Single Player") {
                            singlePlayerMode = true
                            showModeSelection = false
                        }
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        Button("Two Players") {
                            singlePlayerMode = false
                            showModeSelection = false
                        }
                        .font(.title2)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                } else {
                    VStack {
                        // Scoreboard
                        HStack {
                            VStack {
                                Text(player1Name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("\(player1Score) points")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            if !singlePlayerMode {
                                VStack {
                                    Text(player2Name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("\(player2Score) points")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding()

                        // Card Grid
                        ScrollView {
                            let cardWidth = geometry.size.width / 7 - 10
                            let cardHeight = cardWidth * 1.5

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 10) {
                                ForEach(deck.indices, id: \.self) { index in
                                    let card = deck[index]
                                    if matchedCards.contains(card) {
                                        Color.clear
                                            .frame(width: cardWidth, height: cardHeight)
                                    } else {
                                        CardView(card: card, isFlipped: flippedCards.contains(card))
                                            .onTapGesture {
                                                if !isProcessing {
                                                    handleCardFlip(card)
                                                }
                                            }
                                            .disabled(flippedCards.contains(card) || isProcessing)
                                            .frame(width: cardWidth, height: cardHeight)
                                    }
                                }
                            }
                            .padding()
                        }

                        // Current Player Display or Spinner
                        if isProcessing {
                            ProgressView("Processing...")
                                .padding()
                                .foregroundColor(.white)
                        } else if !showWinningMessage {
                            Text("\(currentPlayer == 1 ? player1Name : player2Name)'s Turn")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    .padding()
                }
            }
            .alert(isPresented: $showWinningMessage) {
                let winner: String
                if player1Score > player2Score {
                    winner = "\(player1Name) Wins!"
                } else if player2Score > player1Score {
                    winner = "\(player2Name) Wins!"
                } else {
                    winner = "It's a Tie!"
                }
                return Alert(
                    title: Text("Game Over"),
                    message: Text(winner),
                    dismissButton: .default(Text("Restart")) {
                        resetGame()
                    }
                )
            }
        }
        .onAppear {
            if showModeSelection {
                setupPlayerNames()
            }
        }
    }

    private func setupPlayerNames() {
        if !singlePlayerMode {
            player1Name = "Player 1"
            player2Name = "Player 2"
        } else {
            player1Name = "Player"
        }
    }

    private func handleCardFlip(_ card: Card) {
        guard !flippedCards.contains(card), !matchedCards.contains(card) else { return }
        flippedCards.append(card)
        isProcessing = true

        let matchingCard = flippedCards.first { $0 != card && $0.value == card.value }
        if let match = matchingCard {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                matchedCards.insert(card)
                matchedCards.insert(match)
                flippedCards.removeAll { $0 == card || $0 == match }
                checkGameEnd()
                isProcessing = false
            }
            if currentPlayer == 1 {
                player1Score += 2
            } else {
                player2Score += 2
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                currentPlayer = currentPlayer == 1 ? 2 : 1
                isProcessing = false
            }
        }
    }

    private func checkGameEnd() {
        if matchedCards.count == deck.count {
            showWinningMessage = true
        }
    }

    private func resetGame() {
        deck = Card.generateShuffledDeck()
        flippedCards = []
        matchedCards = []
        player1Score = 0
        player2Score = 0
        currentPlayer = 1
        showWinningMessage = false
        isProcessing = false
    }
}

// Card Struct
struct Card: Hashable {
    let id = UUID()
    let value: Int
    let displayValue: String

    static func generateShuffledDeck() -> [Card] {
        let values = (1...13).flatMap { value -> [Card] in
            let displayValue: String
            switch value {
            case 1: displayValue = "A"
            case 11: displayValue = "J"
            case 12: displayValue = "Q"
            case 13: displayValue = "K"
            default: displayValue = "\(value)"
            }
            return [
                Card(value: value, displayValue: displayValue),
                Card(value: value, displayValue: displayValue),
                Card(value: value, displayValue: displayValue),
                Card(value: value, displayValue: displayValue)
            ]
        }
        return values.shuffled()
    }
}

// Enhanced CardView
struct CardView: View {
    let card: Card
    let isFlipped: Bool

    var body: some View {
        ZStack {
            if !isFlipped {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.cyan]), startPoint: .top, endPoint: .bottom))
                    .overlay(
                        Text("★")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .opacity(0.3)
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .overlay(
                        Text(card.displayValue)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    )
            }
        }
        .frame(width: 50, height: 75)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
        .rotation3DEffect(.degrees(isFlipped ? 0 : 180), axis: (x: 0, y: 1, z: 0))
        .animation(.easeInOut, value: isFlipped)
    }
}

