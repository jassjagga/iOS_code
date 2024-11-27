import SwiftUI

struct ContentView: View {
    @State private var board: [[String]] = Array(repeating: Array(repeating: "", count: 3), count: 3)
    @State private var currentPlayer: String = "X"
    @State private var winner: String? = nil
    @State private var isDraw: Bool = false
    @State private var playerXWins: Int = 0
    @State private var playerOWins: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            // Display Scores
            HStack {
                VStack {
                    Text("Player X")
                        .font(.headline)
                        .foregroundColor(.blue)
                    Text("\(playerXWins)")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                Spacer()
                VStack {
                    Text("Player O")
                        .font(.headline)
                        .foregroundColor(.orange)
                    Text("\(playerOWins)")
                        .font(.title)
                        .foregroundColor(.orange)
                }
            }
            .padding()

            // Winner or Draw Message
            if let winner = winner {
                Text("\(winner) Wins!")
                    .font(.largeTitle)
                    .foregroundColor(winner == "X" ? .blue : .orange)
                    .bold()
            } else if isDraw {
                Text("It's a Draw!")
                    .font(.largeTitle)
                    .foregroundColor(.purple)
                    .bold()
            } else {
                Text("Player \(currentPlayer)'s Turn")
                    .font(.title)
                    .foregroundColor(currentPlayer == "X" ? .blue : .orange)
            }

            // Tic-Tac-Toe Board
            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { column in
                            CellView(symbol: $board[row][column], currentPlayer: currentPlayer) {
                                makeMove(row: row, column: column)
                            }
                        }
                    }
                }
            }
            .background(
                ZStack {
                    // Relaxing gradient background
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.green.opacity(0.3)]),
                        startPoint: UnitPoint(x: 0, y: 0), // Top-left corner
                        endPoint: UnitPoint(x: 1, y: 1)    // Bottom-right corner
                    )
                    .ignoresSafeArea()

                    // Grid lines
                    VStack {
                        Spacer()
                        Rectangle()
                            .frame(height: 3)
                            .foregroundColor(Color.black.opacity(0.6))
                        Spacer()
                        Rectangle()
                            .frame(height: 3)
                            .foregroundColor(Color.black.opacity(0.6))
                        Spacer()
                    }
                    .overlay(
                        HStack {
                            Spacer()
                            Rectangle()
                                .frame(width: 3)
                                .foregroundColor(Color.black.opacity(0.6))
                            Spacer()
                            Rectangle()
                                .frame(width: 3)
                                .foregroundColor(Color.black.opacity(0.6))
                            Spacer()
                        }
                    )
                }
            )
            .aspectRatio(1, contentMode: .fit)
            .padding()

            // Buttons: Restart and New Game
            HStack(spacing: 20) {
                Button(action: resetGame) {
                    Text("Restart")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: newGame) {
                    Text("New Game")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }

    private func makeMove(row: Int, column: Int) {
        if board[row][column].isEmpty && winner == nil && !isDraw {
            board[row][column] = currentPlayer
            if checkForWinner() {
                winner = currentPlayer
                if currentPlayer == "X" {
                    playerXWins += 1
                } else {
                    playerOWins += 1
                }
            } else if checkForDraw() {
                isDraw = true
            } else {
                currentPlayer = currentPlayer == "X" ? "O" : "X"
            }
        }
    }

    private func checkForWinner() -> Bool {
        // Check rows
        for row in board {
            if row.allSatisfy({ $0 == currentPlayer }) {
                return true
            }
        }

        // Check columns
        for column in 0..<3 {
            if (0..<3).allSatisfy({ board[$0][column] == currentPlayer }) {
                return true
            }
        }

        // Check diagonals
        if (0..<3).allSatisfy({ board[$0][$0] == currentPlayer }) ||
           (0..<3).allSatisfy({ board[$0][2 - $0] == currentPlayer }) {
            return true
        }

        return false
    }

    private func checkForDraw() -> Bool {
        for row in board {
            if row.contains("") {
                return false
            }
        }
        return true
    }

    private func resetGame() {
        board = Array(repeating: Array(repeating: "", count: 3), count: 3)
        currentPlayer = "X"
        winner = nil
        isDraw = false
    }

    private func newGame() {
        resetGame()
        playerXWins = 0
        playerOWins = 0
    }
}

struct CellView: View {
    @Binding var symbol: String
    var currentPlayer: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(symbol)
                .font(.largeTitle)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundColor(symbol == "X" ? .blue : .orange)
                .background(
                    Color.white
                        .shadow(color: .gray.opacity(0.5), radius: 3, x: 0, y: 3)
                )
                .cornerRadius(10)
                .animation(.easeInOut, value: symbol)
        }
        .disabled(!symbol.isEmpty)
    }
}


